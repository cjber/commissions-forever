#!/usr/bin/env python3
"""Check that each README screenshot still matches its scene inputs."""

from pathlib import Path

from forever_tools.screens import files, main

ROOT = Path(__file__).resolve().parents[1]
WINDOW_SOURCES = [
    "tools/screenshots.py",
    "UI/RowArt.lua",
    "UI/Window.lua",
    "Data/TurnIns.lua",
    "Core/Core.lua",
    "Core/Model.lua",
    "Integrations/Questie.lua",
    "Locales/enUS.lua",
]
# The leaderboard window itself is ForeverCore's UI/Leaderboards.lua; this addon supplies its board's rows and labels.
LEADERBOARD_SOURCES = [
    "tools/screenshots.py",
    "Core/Stats.lua",
    "Locales/enUS.lua",
]
SCENES = {
    "window.png": lambda: files(ROOT, WINDOW_SOURCES),
    "window-search.png": lambda: files(ROOT, WINDOW_SOURCES),
    "leaderboard.png": lambda: files(ROOT, LEADERBOARD_SOURCES),
    "leaderboard-all-time.png": lambda: files(ROOT, LEADERBOARD_SOURCES),
}

if __name__ == "__main__":
    raise SystemExit(main(ROOT / "docs" / "screenshots", SCENES))
