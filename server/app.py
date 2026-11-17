import asyncio
import hashlib
import hmac
import json
import math
import os
import re
import secrets
import sqlite3
import time
from contextlib import asynccontextmanager, contextmanager
from pathlib import Path

import psycopg
from fastapi import FastAPI, HTTPException, Request, WebSocket, WebSocketDisconnect
from fastapi.staticfiles import StaticFiles

ROOT = Path(__file__).resolve().parents[1]
DATABASE_URL = os.environ.get("DATABASE_URL")
ALLOWED_ORIGIN = os.environ.get("ALPHA_ORIGIN", "")
LOCAL_DEV = os.environ.get("ALPHA_LOCAL_DEV") == "1"
INVITES = set(os.environ.get("ALPHA_INVITE_HASHES", "").split(","))
PLAYER_LIMIT = 10
SPAWN = (-3574.0, 1265.0)
WEAPONS = {"fist": (1.8, 14, .45), "knife": (2.25, 24, .43), "bat": (3.05, 30, .64),
           "crowbar": (3.05, 38, .7), "pistol": (18, 55, .55),
           "shotgun": (13, 85, .93), "rifle": (30, 65, .64)}
FIREARMS = {"pistol", "shotgun", "rifle"}
peers = {}
infected = {}
sounds = []
recent = {}


def road_cells():
    city = json.loads((ROOT / "data/city.json").read_text(encoding="utf-8"))
    cells = {}
    for road in city["roads"]:
        if road["k"] not in {"residential", "primary", "secondary", "tertiary", "living_street"}:
            continue
        points = road["p"]
        for a, b in zip(points, points[1:]):
            segments = max(1, math.ceil(math.dist(a, b) / 9))
            for step in range(segments):
                u = step / segments
                x, y = (a[0] + (b[0] - a[0]) * u, a[1] + (b[1] - a[1]) * u)
                cells.setdefault((math.floor(x / 48), math.floor(y / 48)), []).append((x, y))
    return cells


ROADS = road_cells()


def spawn_near(x, y):
    cx, cy = math.floor(x / 48), math.floor(y / 48)
    options = [candidate for dx in (-1, 0, 1) for dy in (-1, 0, 1)
               for candidate in ROADS.get((cx + dx, cy + dy), ())
               if 22 <= math.dist((x, y), candidate) <= 42]
    return secrets.choice(options) if options else None


def digest(value):
    return hashlib.sha256(value.encode()).hexdigest()


@contextmanager
def database():
    connection = psycopg.connect(DATABASE_URL) if DATABASE_URL else sqlite3.connect(os.environ["ALPHA_SQLITE"])
    try:
        with connection:
            yield connection
    finally:
        connection.close()


def execute(connection, statement, parameters=()):
    if DATABASE_URL:
        statement = statement.replace("?", "%s")
    return connection.execute(statement, parameters)


def password_hash(password, salt):
    return hashlib.scrypt(password.encode(), salt=bytes.fromhex(salt), n=2**14, r=8, p=1).hex()


def permit(origin):
    if ALLOWED_ORIGIN and origin == ALLOWED_ORIGIN:
        return True
    if os.environ.get("RENDER_EXTERNAL_URL") and origin == os.environ["RENDER_EXTERNAL_URL"]:
        return True
    return LOCAL_DEV and bool(re.fullmatch(r"http://(?:127\.0\.0\.1|localhost):\d{1,5}", origin or ""))


def rate_limit(key):
    now = time.monotonic()
    if len(recent) > 500:
        for old in list(recent):
            if recent[old][1] <= now:
                recent.pop(old)
    count, until = recent.get(key, (0, now + 60))
    if until <= now:
        count, until = 0, now + 60
    if count >= (40 if key.startswith("ip:") else 8):
        raise HTTPException(429, "Aguarde antes de tentar de novo.")
    recent[key] = (count + 1, until)


@asynccontextmanager
async def lifespan(_app):
    if not DATABASE_URL and not LOCAL_DEV:
        raise RuntimeError("DATABASE_URL é obrigatório fora do desenvolvimento.")
    with database() as db:
        execute(db, "CREATE TABLE IF NOT EXISTS accounts (id TEXT PRIMARY KEY, login TEXT UNIQUE NOT NULL, salt TEXT NOT NULL, password TEXT NOT NULL, invite TEXT UNIQUE NOT NULL)")
        execute(db, "CREATE TABLE IF NOT EXISTS sessions (token TEXT PRIMARY KEY, account TEXT NOT NULL REFERENCES accounts(id), expires DOUBLE PRECISION NOT NULL)")
    world = asyncio.create_task(tick_world())
    yield
    world.cancel()


app = FastAPI(lifespan=lifespan, docs_url=None, redoc_url=None, openapi_url=None)


@app.middleware("http")
async def secure_headers(request: Request, next_handler):
    response = await next_handler(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["Referrer-Policy"] = "same-origin"
    if request.url.path.startswith("/api/"):
        response.headers["Cache-Control"] = "no-store"
    return response


@app.get("/health")
def health():
    with database() as db:
        execute(db, "SELECT 1")
    return {"status": "ok"}


@app.post("/api/{action}")
async def authenticate(action: str, request: Request):
    if action not in {"register", "login"}:
        raise HTTPException(404)
    if request.headers.get("origin") and not permit(request.headers["origin"]):
        raise HTTPException(403, "Origem inválida.")
    rate_limit(f"ip:{request.client.host}")
    body = bytearray()
    async for chunk in request.stream():
        body.extend(chunk)
        if len(body) > 2048:
            raise HTTPException(413)
    try:
        content = json.loads(body)
        login = content["login"].strip().lower()
        password = content["password"]
        invite = content.get("invite", "").strip()
        if not isinstance(password, str):
            raise ValueError()
    except (ValueError, KeyError, TypeError, AttributeError):
        raise HTTPException(400, "Dados inválidos.")
    if not re.fullmatch(r"[a-z0-9_]{3,24}", login) or not 10 <= len(password) <= 72:
        raise HTTPException(400, "Use 3–24 letras, números ou _ no usuário e 10–72 caracteres na senha.")
    rate_limit(f"login:{login}")
    return await asyncio.to_thread(open_session, action, login, password, invite)


def open_session(action, login, password, invite):
    now = time.time()
    with database() as db:
        if action == "register":
            invite_hash = digest(invite)
            if invite_hash not in INVITES:
                raise HTTPException(403, "Convite inválido.")
            account, salt = secrets.token_hex(12), secrets.token_hex(16)
            try:
                execute(db, "INSERT INTO accounts (id, login, salt, password, invite) VALUES (?, ?, ?, ?, ?)",
                        (account, login, salt, password_hash(password, salt), invite_hash))
            except (sqlite3.IntegrityError, psycopg.IntegrityError):
                raise HTTPException(409, "Usuário ou convite já utilizado.")
        else:
            row = execute(db, "SELECT id, salt, password FROM accounts WHERE login = ?", (login,)).fetchone()
            actual = password_hash(password, row[1] if row else "0" * 32)
            if not row or not hmac.compare_digest(actual, row[2]):
                raise HTTPException(401, "Usuário ou senha incorretos.")
            account = row[0]
        token = secrets.token_urlsafe(32)
        execute(db, "DELETE FROM sessions WHERE expires < ? OR account = ?", (now, account))
        expires = now + 43200
        execute(db, "INSERT INTO sessions VALUES (?, ?, ?)", (digest(token), account, expires))
    return {"id": account, "token": token, "expires": expires}


def session(token):
    if not isinstance(token, str) or len(token) != 43:
        return None
    with database() as db:
        return execute(db, "SELECT a.id, a.login, s.expires FROM accounts a JOIN sessions s ON s.account = a.id WHERE s.token = ? AND s.expires > ?",
                       (digest(token), time.time())).fetchone()


def coordinate(payload, key):
    value = payload.get(key)
    return float(value) if type(value) in (float, int) and math.isfinite(value) and abs(value) < 13000 else None


@app.websocket("/world")
async def world(socket: WebSocket):
    origin = socket.headers.get("origin")
    if (origin and not permit(origin)) or (not origin and not DATABASE_URL and not LOCAL_DEV):
        await socket.close(1008)
        return
    await socket.accept()
    identity = None
    try:
        login = await asyncio.wait_for(socket.receive_json(), timeout=4)
        if not isinstance(login, dict):
            return
        account = await asyncio.to_thread(session, login.get("token"))
        if not account or len(peers) >= PLAYER_LIMIT or account[0] in peers:
            await socket.close(1008)
            return
        identity, username, expiry = account
        peer = peers[identity] = {"id": identity, "name": username, "x": SPAWN[0], "y": SPAWN[1],
                                  "online": False, "inside": False, "moving": False, "face": 1,
                                  "since": time.monotonic(), "strike": 0, "hurt": 0, "sequence": 0, "next_noise": 0}
        await socket.send_json({"kind": "ready", "id": identity})
        while time.time() < expiry:
            raw = await asyncio.wait_for(socket.receive_text(), timeout=12)
            if len(raw) > 768:
                await socket.close(1009)
                return
            message = json.loads(raw)
            if not isinstance(message, dict):
                return
            now = time.monotonic()
            kind = message.get("kind")
            if kind == "pose":
                update_pose(peer, message, now)
            elif kind == "attack":
                attack(peer, message, now)
            elif kind == "noise":
                sound(peer, message, now)
            elif kind == "revive" and peer["inside"]:
                peer["online"] = False
            if now - peer.get("last_snapshot", 0) < .07:
                continue
            peer["last_snapshot"] = now
            await socket.send_json(snapshot(peer))
    except (TimeoutError, ValueError, RuntimeError, WebSocketDisconnect):
        pass
    finally:
        if identity:
            peers.pop(identity, None)
        try:
            await socket.close()
        except RuntimeError:
            pass


def update_pose(peer, message, now):
    x, y = coordinate(message, "x"), coordinate(message, "y")
    if x is None or y is None or now - peer["since"] < .07:
        return
    elapsed = now - peer["since"]
    driving = message.get("driving") is True
    distance = math.hypot(x - peer["x"], y - peer["y"])
    limit = 125 if peer["inside"] else (42 if driving else 9) * min(elapsed, 2.0) + 1.2
    if peer["online"] and distance > limit:
        return
    peer.update(x=x, y=y, online=True, inside=message.get("inside") is True,
                driving=driving, moving=distance > .15, face=0 if message.get("face") == 0 else 1, since=now)


def attack(peer, message, now):
    weapon = message.get("weapon")
    if not isinstance(weapon, str) or not peer["online"] or peer["inside"] or peer.get("driving") or weapon not in WEAPONS:
        return
    reach, damage, delay = WEAPONS[weapon]
    if now < peer["strike"]:
        return
    peer["strike"] = now + delay
    firearm = weapon in FIREARMS
    if firearm and len(sounds) < 80:
        sounds.append((peer["x"], peer["y"], 75, now + 6))
    direction = (coordinate(message, "aim_x"), coordinate(message, "aim_y"))
    aimed = firearm and all(value is not None for value in direction) and .95 < math.hypot(*direction) < 1.05
    maximum = coordinate(message, "range") if aimed else None
    if maximum is not None:
        reach = min(reach, max(0, maximum + .45))
    candidates = []
    for zombie in infected.values():
        if zombie["hp"] <= 0:
            continue
        dx = zombie["x"] - peer["x"]
        dy = zombie["y"] - peer["y"]
        distance = math.hypot(dx, dy)
        if aimed:
            ax, ay = direction
            distance = dx * ax + dy * ay
            if distance <= 0 or abs(dx * ay - dy * ax) > .96:
                continue
        if distance <= reach:
            candidates.append((distance, zombie))
    if candidates:
        _, zombie = min(candidates, key=lambda item: item[0])
        zombie["hp"] = max(0, zombie["hp"] - damage)
        zombie["hit"] += 1
        zombie["dead"] = now + 10


def sound(peer, message, now):
    x, y = coordinate(message, "x"), coordinate(message, "y")
    if x is None or y is None or not peer["online"] or peer["inside"] or now < peer["next_noise"]:
        return
    if math.hypot(x - peer["x"], y - peer["y"]) > 20 or len(sounds) >= 80:
        return
    peer["next_noise"] = now + 1
    sounds.append((x, y, 51, now + 5))


def snapshot(peer):
    player_fields = ("id", "name", "x", "y", "moving", "face", "driving")
    players = [{k: other[k] for k in player_fields} for other in peers.values()
               if other is not peer and other["online"] and not other["inside"]]
    zombies = [z for z in infected.values() if math.hypot(z["x"] - peer["x"], z["y"] - peer["y"]) < 110]
    return {"kind": "snapshot", "players": players, "infected": zombies, "hurt": peer["hurt"], "sequence": peer["sequence"]}


async def tick_world():
    last_spawn = 0
    while True:
        await asyncio.sleep(.10)
        now = time.monotonic()
        outside = [p for p in peers.values() if p["online"] and not p["inside"]]
        sounds[:] = [noise for noise in sounds if noise[3] > now]
        for identity, zombie in list(infected.items()):
            if not outside or (not zombie["hp"] and zombie["dead"] <= now):
                infected.pop(identity)
                continue
            if not zombie["hp"]:
                continue
            target = min(outside, key=lambda p: math.hypot(p["x"]-zombie["x"], p["y"]-zombie["y"]))
            dx, dy = target["x"]-zombie["x"], target["y"]-zombie["y"]
            distance = math.hypot(dx, dy)
            if distance > 135:
                infected.pop(identity)
            elif 1.45 < distance < 30:
                zombie["x"] += dx / distance * .23
                zombie["y"] += dy / distance * .23
            elif distance >= 30:
                heard = next((noise for noise in reversed(sounds) if 1 < math.hypot(noise[0]-zombie["x"], noise[1]-zombie["y"]) < noise[2]), None)
                if heard:
                    nx, ny = heard[0]-zombie["x"], heard[1]-zombie["y"]
                    norm = math.hypot(nx, ny)
                    zombie["x"] += nx / norm * .14
                    zombie["y"] += ny / norm * .14
            elif distance <= 1.45 and now >= zombie["bite"] and not target.get("driving"):
                zombie["bite"] = now + 1.7
                target["hurt"] = 8
                target["sequence"] += 1
        if outside and len(infected) < min(3 * len(outside), 20) and now - last_spawn > 3.5:
            target = min(outside, key=lambda p: sum(math.hypot(z["x"]-p["x"], z["y"]-p["y"]) < 45 for z in infected.values()))
            spawn = spawn_near(target["x"], target["y"])
            if spawn is None:
                last_spawn = now
                continue
            identity = secrets.token_hex(4)
            infected[identity] = {"id": identity, "x": spawn[0], "y": spawn[1],
                                  "hp": 65, "hit": 0, "bite": 0, "dead": 0}
            last_spawn = now


app.mount("/alpha", StaticFiles(directory=ROOT / "docs", html=True), name="alpha")
