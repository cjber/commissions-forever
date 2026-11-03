#!/usr/bin/env python3
"""Render the native Professions ledger from UI anchors and real model output."""

import json
import os
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CORE = Path(os.environ.get("FOREVER_CORE", ROOT.parent / "forever-core"))
sys.path.insert(0, str(CORE / "tools" / "wowmock"))
import wowmock  # noqa: E402

SOURCE = (ROOT / "UI" / "Window.lua").read_text()
ROW_HEIGHT = int(re.search(r"local ROW_HEIGHT = (\d+)", SOURCE)[1])
WIDTH, HEIGHT = 673, 594  # Blizzard_Professions/Camelot/Blizzard_ProfessionsFrame.xml
X, Y = 24, 24


def sample_rows():
    """Use the same sorting and bag-only filtering as the client, without Questie data."""
    result = subprocess.run(
        [
            "luajit",
            "-e",
            """local ns = {}
assert(loadfile("Data/TurnIns.lua"))("CommissionsForever", ns)
assert(loadfile("Core/Model.lua"))("CommissionsForever", ns)
local bags = {[12844]=3,[11370]=12,[17012]=4,[11382]=1,[17010]=2,[17011]=1,
              [21377]=8,[21383]=5,[20741]=1,[11040]=6,[11018]=15}
for _, row in ipairs(ns.Model.Inventory(function(id) return bags[id] or 0 end, {})) do
    print(row.itemID .. "\\t" .. row.count .. "\\t" .. row.turnIn.faction)
end""",
        ],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=True,
    )
    return [line.split("\t") for line in result.stdout.splitlines()]


def window(ui, *, sharing=True, empty=False, available=True):
    canvas = ui.canvas(765, 642)
    canvas.draw(ui.atlas("Profession-Background-Overview"), X + 2, Y + 21, WIDTH - 4, HEIGHT - 23)
    canvas.draw(ui.atlas("Profession-Background-Template2"), X + 3, Y + 21)
    wowmock.portrait_frame_art(canvas, X, Y, WIDTH, HEIGHT, 136241, "Professions")
    wowmock.side_tab(canvas, X + WIDTH, Y + 60, 136241)
    wowmock.side_tab(canvas, X + WIDTH, Y + 116, "interface/icons/inv_misc_note_01.blp", selected=True)
    px, py = X + 4, Y + 28  # page TOPLEFT
    canvas.text(px + 74, py + 12, "Commissions Forever", wowmock.FONTS["GameFontNormalLarge"])
    wowmock.ui_panel_button(canvas, px + WIDTH - 8 - 14 - 132, py + 8, 132, 24, "Leaderboard")
    wowmock.search_box(canvas, px + 22, py + 48, 250)
    if not available:
        canvas.text(
            px + 288,
            py + 52,
            "Install QuestieDB to see your active turn-ins.",
            wowmock.FONTS["GameFontDisableSmall"],
            width=350,
        )
    ix, iy = px + 14, py + 78
    iw, ih = WIDTH - 8 - 28, HEIGHT - 32 - 78 - 44
    canvas.draw(ui.atlas("Professions-background-summarylist"), ix + 2, iy + 2, iw - 4, ih - 4)
    canvas.nine_slice(wowmock.INSET_FRAME_LAYOUT, ix, iy, iw, ih)
    columns = re.findall(r'\{ "(Material|Turn-in|Have|Need)", (\d+), (\d+) \}', SOURCE)
    for label, offset, width in columns:
        canvas.text(ix + int(offset), iy + 10, label, wowmock.FONTS["GameFontNormalSmall"], width=int(width))
    if empty:
        canvas.text(ix + 12, iy + 42, "No tracked materials found", wowmock.FONTS["GameFontDisableSmall"], width=560)
    for index, (item_id, count, source) in enumerate([] if empty else sample_rows()):
        # Scroll content TOPLEFT (4,-32), each row TOPLEFT (4,-index*ROW_HEIGHT).
        rx, ry = ix + 8, iy + 32 + index * ROW_HEIGHT
        item = ui.item(int(item_id))
        canvas.draw(ui.texture(item.icon), rx + 4, ry + 3, 24, 24)
        for offset, text, font, width in [
            (36, item.name, "GameFontHighlight", 218),
            (260, source, "GameFontHighlightSmall", 170),
            (440, count, "GameFontHighlight", 64),
            (510, "-", "GameFontHighlight", 64),
        ]:
            canvas.text(rx + offset, ry + 8, text, wowmock.FONTS[font], width=width)
    wowmock.minimal_scrollbar(canvas, ix + iw - 22, iy + 32, ih - 36)
    bx, by = px + WIDTH - 8 - 14 - 190, Y + HEIGHT - 4 - 10 - 24
    wowmock.ui_panel_button(canvas, bx, by, 190, 24, "Open turn-in route")
    wowmock.minimal_checkbox(
        canvas, px + 14, Y + HEIGHT - 4 - 9 - 26, "Share totals with guild and group", size=26, checked=sharing
    )
    layout = {
        "frame": {"x": X, "y": Y, "w": WIDTH, "h": HEIGHT},
        "widgets": [
            {"name": "leaderboard", "role": "button", "x": px + WIDTH - 8 - 14 - 132, "y": py + 8, "w": 132, "h": 24},
            {"name": "sharing", "role": "input", "x": px + 14, "y": Y + HEIGHT - 4 - 9 - 26, "w": 329, "h": 26},
            {"name": "search", "role": "input", "x": px + 22, "y": py + 48, "w": 250, "h": 20},
            {"name": "ledger", "role": "list", "x": ix, "y": iy, "w": iw, "h": ih},
            {"name": "route", "role": "button", "x": bx, "y": by, "w": 190, "h": 24},
        ],
    }
    return canvas, layout


def main():
    ui = wowmock.Ui(scale=2)
    output = ROOT / "docs" / "screenshots"
    output.mkdir(parents=True, exist_ok=True)
    variants = {
        "window.png": {},
        "sharing-off.png": {"sharing": False},
        "empty.png": {"empty": True},
        "questiedb-missing.png": {"available": False},
    }
    for name, state in variants.items():
        canvas, layout = window(ui, **state)
        wowmock.scene(ui, [(canvas, 0, 0)]).save(output / name)
        print(output / name)
    (output / "layout.json").write_text(json.dumps(layout, indent=2) + "\n")


if __name__ == "__main__":
    main()
