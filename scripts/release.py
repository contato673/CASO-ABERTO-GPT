"""Stamp a playable release and bind its web loader to that same version."""
import argparse
import json
import re
from pathlib import Path
from uuid import uuid4

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "project.godot"
VERSION = re.compile(r'^config/version="([a-f0-9]{12})"$', re.MULTILINE)


def prepare() -> None:
    config = PROJECT.read_text(encoding="utf-8")
    version = uuid4().hex[:12]
    setting = f'config/version="{version}"'
    if VERSION.search(config):
        config = VERSION.sub(setting, config)
    elif "config/version=" in config:
        raise ValueError("Formato inesperado em config/version")
    else:
        config = config.replace("[application]\n", f"[application]\n\n{setting}\n", 1)
    PROJECT.write_text(config, encoding="utf-8", newline="\n")
    print(version)


def web(index: Path) -> None:
    stamp = VERSION.search(PROJECT.read_text(encoding="utf-8"))
    if stamp is None:
        raise ValueError("Execute prepare antes de exportar")
    version = stamp.group(1)
    html = index.read_text(encoding="utf-8")
    config = re.search(r"const GODOT_CONFIG = (\{[^\n]+\});", html)
    if config is None or html.count("engine.startGame({") != 1:
        raise ValueError("O HTML precisa estar recém-exportado pelo Godot")
    settings = json.loads(config.group(1))
    pack = f"index.pck?v={version}"
    settings["fileSizes"][pack] = settings["fileSizes"].pop("index.pck")
    settings["args"] = ["--main-pack", "index.pck", *settings["args"]]
    html = html.replace("</head>", f'<meta name="game-release" content="{version}">\n</head>', 1)
    html = html.replace("(function () {", """(async function() {
	// Revalidate the launcher even if the browser opened a cached copy.
	try {
		const response = await fetch("index.html?check=" + Date.now(), {
			cache: "no-store", signal: AbortSignal.timeout(3500)
		});
		if (response.ok) {
			const newest = (await response.text()).match(/<meta name="game-release" content="([a-f0-9]{12})">/);
			const current = document.querySelector('meta[name="game-release"]').content;
			if (newest && newest[1] !== current) {
				const url = new URL(location.href);
				if (url.searchParams.get("v") !== newest[1]) {
					url.searchParams.set("v", newest[1]);
					location.replace(url);
					return;
				}
			}
		}
	} catch (_) {
		// The stamped release can still be playable when the check is unavailable.
	}
""", 1)
    html = html.replace(config.group(0), f"const GODOT_CONFIG = {json.dumps(settings, separators=(',', ':'))};")
    html = html.replace('src="index.js"', f'src="index.js?v={version}"')
    html = html.replace(
        "engine.startGame({",
        f'Promise.all([engine.init("index"), engine.preloadFile("{pack}", "index.pck")]).then(() => engine.start({{',
    )
    html = html.replace("}).then(() => {\n\t\t\tsetStatusMode('hidden');", "})).then(() => {\n\t\t\tsetStatusMode('hidden');")
    index.write_text(html, encoding="utf-8", newline="\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("prepare")
    web_command = commands.add_parser("web")
    web_command.add_argument("index", type=Path)
    args = parser.parse_args()
    if args.command == "prepare":
        prepare()
    else:
        web(args.index)
