#!/usr/bin/env python3
"""Check that each README screenshot still matches its scene inputs."""

from pathlib import Path

from forever_tools.screens import files, main

ROOT = Path(__file__).resolve().parents[1]
SCENES = {
    "window.png": lambda: files(ROOT, ["tools/screenshots.py", "UI/Window.lua", "Data/TurnIns.lua"]),
}

if __name__ == "__main__":
    raise SystemExit(main(ROOT / "docs" / "screenshots", SCENES))
