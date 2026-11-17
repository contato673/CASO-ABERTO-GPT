from io import BytesIO
from pathlib import Path
from zipfile import ZipFile
import json
from PIL import Image

root = Path(__file__).resolve().parents[1]
downloads = Path.home() / "Downloads"
art = root / "assets/interiores"
local = root / "assets/interiores_locais"
art.mkdir(exist_ok=True)
local.mkdir(exist_ok=True)

packs = {
    "household_kitchen_dining_sprites_v1.0.zip": {"fridge":"01", "stove":"02", "kitchen_sink":"05", "cupboard":"09", "island":"10", "table":"11", "chair":"12"},
    "household_bathroom_laundry_sprites_v1.0.zip": {"bath":"01", "toilet":"03", "sink":"04", "medicine":"05", "washer":"07"},
    "household_living_bedroom_sprites_v1.0.zip": {"sofa":"01", "coffee":"05", "shelf":"08", "bed":"09", "nightstand":"12", "wardrobe":"15"},
    "household_electronics_home_details_sprites_v1.0.zip": {"desk":"01", "office_chair":"02", "tv":"07", "plant":"18", "radio":"24"},
    "household_essentials_sprites_v1.0.zip": {"basket":"05", "trash":"12", "parcel":"24"},
}
def asset(archive, path, dest):
    with Image.open(BytesIO(archive.read(path))) as im:
        im = im.convert("RGBA")
        im = im.crop(im.getbbox())
        im.thumbnail((192, 192), Image.Resampling.NEAREST)
        im.save(dest, optimize=True)

for pack, files in packs.items():
    with ZipFile(downloads / pack) as z:
        for name, prefix in files.items():
            source = next(n for n in z.namelist() if "/sprites/" in n and n.rsplit("/", 1)[-1].startswith(prefix + "_"))
            asset(z, source, art / f"{name}.png")
with ZipFile(downloads / "household_appliances_release.zip") as z:
    asset(z, "household_appliances/vacuum/vacuum01_transparent.png", art / "vacuum.png")
with ZipFile(downloads / "thirdangle-police-station-starter.zip") as z:
    for name, f in {"evidence":"evidence_locker_bank", "reception":"police_front_desk", "interrogation":"interrogation_table_set"}.items():
        asset(z, f"thirdangle-police-station-starter/{f}.png", local / f"{name}.png")
with ZipFile(downloads / "thirdangle-police-station-starter.zip") as z:
    name = "thirdangle-police-station-starter/wall_plain_left.png"
    wall = Image.open(BytesIO(z.read(name))).convert("RGBA")
    # Select the solid middle of the supplied wall tile for use on 3D walls.
    samples = (wall.crop((x, y, x + 24, y + 24))
               for y in range(13, 75, 3) for x in range(10, 37, 3))
    panel = next(sample for sample in samples if sample.getchannel("A").getextrema() == (255, 255))
    panel.save(local / "wall_panels.png", optimize=True)
    asset(z, "thirdangle-police-station-starter/wall_lineup_height_lines_left.png", local / "lineup.png")
with ZipFile(downloads / "hvnbnn-korean-street-stall-lite-v1.0.zip") as z:
    for name in ("curbside_bins", "fruit_handcart", "folding_steel_table", "ice_cooler", "street_bench", "traffic_cone"):
        path = next(n for n in z.namelist() if n.endswith(f"/glb/{name}.glb"))
        (local / f"{name}.glb").write_bytes(z.read(path))
with ZipFile(downloads / "36-classroom-school-3d-pixel-art-kit.zip") as z:
    for name, f in {"student":"student_desk", "teacher":"teacher_desk", "chalk":"chalkboard", "cubbies":"cubby_shelves"}.items():
        asset(z, f"isometric/png_64/classroom/{f}.png", local / f"{name}.png")
with ZipFile(downloads / "Urban RuinsAssetPack.zip") as z:
    for name, f in {"drum":"Oil_drum", "crate":"ammunition_crate", "generator":"generator", "barricade":"barricade", "rubble":"broken_glass", "medical_case":"medical_case", "electronic_parts":"electronic_parts","street_drum":"Oil_drum (7)","street_rubble":"rubble_piles",
                    "street_wire":"barbed_wire","street_cone":"Traffic_cone","street_dumpster":"dumpster",
                    "street_tires":"tires_pile","street_scrap":"scrap_heap","street_papers":"scattered_papers",
                    "street_supply":"Supply_crate","street_metal":"Scrap_metal"}.items():
        asset(z, f+".png", local / f"{name}.png")

for action in ("Idle", "Walk", "Running", "Carrying"):
    with ZipFile(downloads / (action + ".zip")) as z:
        rows = []
        for direction in range(1, 9):
            name = f"{action}/Businessman_{action}_dir{direction}"
            sheet = Image.open(BytesIO(z.read(name+".png"))).convert("RGBA")
            data = json.loads(z.read(name+".json"))
            frames = []
            for row in data["frames"]:
                frame = row["frame"]
                x, y, w, h = (frame[k] for k in ("x","y","w","h"))
                im = sheet.crop((x, y, x+w, y+h))
                frames.append(im)
            rows.append(frames)
        boxes = [f.getbbox() for row in rows for f in row if f.getbbox()]
        left, top = min(b[0] for b in boxes), min(b[1] for b in boxes)
        right, bottom = max(b[2] for b in boxes), max(b[3] for b in boxes)
        # Fixed frame size and a common anchor keep the feet stable when changing direction.
        width, height = 96, 112
        atlas = Image.new("RGBA", (width * max(map(len, rows)), height * 8))
        for i, row in enumerate(rows):
            for j, frame in enumerate(row):
                im = frame.crop((left, top, right, bottom))
                x, y = (width - im.width) // 2, height - im.height - 3
                atlas.paste(im, (j * width + x, i * height + y))
        atlas.save(art / f"actor_{action.lower()}.png", optimize=True)
