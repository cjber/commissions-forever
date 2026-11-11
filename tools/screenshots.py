#!/usr/bin/env python3
"""Render Commissions Forever's surfaces from its UI anchors and real model output."""

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
TOC_TEXT = (ROOT / "CommissionsForever.toc").read_text(encoding="utf-8-sig")
TOC_METADATA = dict(re.findall(r"^##\s*([^:]+):\s*(.*?)\s*$", TOC_TEXT, re.MULTILINE))
ART = (ROOT / "UI" / "RowArt.lua").read_text()
ROW_HEIGHT = int(re.search(r"local ROW_HEIGHT = (\d+)", SOURCE)[1])
ROW_WIDTH = 576  # Window.list is 584 wide, minus the row's 4-unit left and right insets.
NATIVE_ROW_HEIGHT = int(re.search(r"local NATIVE_HEIGHT = (\d+)", ART)[1])  # WhoList.xml draws these on a 69-high row.
WIDTH, HEIGHT = 673, 594  # Blizzard_Professions/Camelot/Blizzard_ProfessionsFrame.xml
X, Y = 24, 24

# Every identity surface draws the icon the TOC declares, the same value the addon reads at load.
COMMISSIONS_ICON = TOC_METADATA["X-Forever-Icon"].replace("\\", "/").lower()
if not COMMISSIONS_ICON.endswith(".blp"):
    COMMISSIONS_ICON += ".blp"


def row_atlas(canvas, ui, name, x, y, width, height):
    """Draw a Who list row piece at native height, scaled uniformly, with only its ends kept out of the stretch."""
    atlas = ui.atlas(name)
    scale = height / NATIVE_ROW_HEIGHT
    density = atlas.image.width / atlas.width
    left, _, right, _ = atlas.slice
    left_px, right_px = round(left * density), round(right * density)
    for source, offset, piece_width in (
        (atlas.image.crop((0, 0, left_px, atlas.image.height)), 0, left * scale),
        (
            atlas.image.crop((left_px, 0, atlas.image.width - right_px, atlas.image.height)),
            left * scale,
            width - (left + right) * scale,
        ),
        (
            atlas.image.crop((atlas.image.width - right_px, 0, atlas.image.width, atlas.image.height)),
            width - right * scale,
            right * scale,
        ),
    ):
        canvas.draw(source, x + offset, y, piece_width, height)


# A deterministic quest log for the render: eight live commission assignments with their QuestieDB objectives, and
# the held materials that belong to no active assignment. The model and the client sort and format them, so the
# screenshots follow Core/Model.lua and UI/Window.lua rather than a hand-written list.
OBJECTIVES = """{
    { questID = 1001, questName = "Bandages for the Field", sourceItemID = 20806, itemID = 14529, required = 30 },
    { questID = 1002, questName = "Feathers for Nafien", itemID = 21377, required = 5 },
    { questID = 1003, questName = "Beads for Salfa", itemID = 21383, required = 5 },
    { questID = 1004, questName = "Morrowgrain", itemID = 11040, required = 10 },
    { questID = 1005, questName = "Un'Goro Soil", itemID = 11018, required = 20 },
    { questID = 1006, questName = "Favor Amongst the Brotherhood", itemID = 11370, required = 10 },
    { questID = 1007, questName = "Favor Amongst the Brotherhood", itemID = 17012, required = 2 },
    { questID = 1008, questName = "Favor Amongst the Brotherhood", itemID = 11382, required = 1 },
}"""
# The category QuestieDB would give each synthetic quest ID.
CATEGORIES = """{
    [1001] = "cenarionCircle", [1002] = "timbermawHold", [1003] = "timbermawHold", [1004] = "morrowgrain",
    [1005] = "morrowgrain", [1006] = "thoriumBrotherhood", [1007] = "thoriumBrotherhood", [1008] = "thoriumBrotherhood",
}"""
BAGS = """{
    [14529] = 22, [21377] = 5, [21383] = 2, [11040] = 12, [11018] = 7, [11370] = 4,
    [17012] = 6, [11382] = 1, [17010] = 2, [17011] = 1, [20741] = 1, [20742] = 1, [12844] = 3,
}"""


def sample_rows(objectives=OBJECTIVES):
    """Use the same sorting, active-assignment merge and bag-only filtering as the client."""
    result = subprocess.run(
        [
            "luajit",
            "-e",
            f"""local ns = {{}}
assert(loadfile("Data/TurnIns.lua"))("CommissionsForever", ns)
local bags = {BAGS}
local objectives = {objectives}
local categories = {CATEGORIES}
-- The scene is synthetic, so QuestieDB's answer per quest ID comes from CATEGORIES.
ns.Questie = {{
    CommissionCategory = function(questID)
        return categories[questID]
    end,
}}
assert(loadfile("Core/Model.lua"))("CommissionsForever", ns)
for _, row in ipairs(ns.Model.Inventory(function(id) return bags[id] or 0 end, objectives)) do
    print(row.itemID .. "\\t" .. row.count .. "\\t" .. (row.need and tostring(row.need) or "-")
        .. "\\t" .. row.turnIn.faction)
end""",
        ],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=True,
    )
    rows = []
    for line in result.stdout.splitlines():
        item_id, count, need, source = line.split("\t")
        rows.append(
            {
                "itemID": int(item_id),
                "count": int(count),
                "need": None if need == "-" else int(need),
                "source": source,
            }
        )
    return rows


def window(ui, *, query="", bag_only=False):
    rows = sample_rows("{}" if bag_only else OBJECTIVES)
    if query:
        needle = query.lower()
        rows = [row for row in rows if needle in ui.item(row["itemID"]).name.lower() or needle in row["source"].lower()]
    canvas = ui.canvas(765, 642)
    canvas.draw(ui.atlas("Profession-Background-Overview"), X + 2, Y + 21, WIDTH - 4, HEIGHT - 23)
    canvas.draw(ui.atlas("Profession-Background-Template2"), X + 3, Y + 21)
    wowmock.portrait_frame_art(canvas, X, Y, WIDTH, HEIGHT, 136241, "Professions")
    wowmock.side_tab(canvas, X + WIDTH, Y + 60, 136241)
    wowmock.side_tab(canvas, X + WIDTH, Y + 116, COMMISSIONS_ICON, selected=True)
    px, py = X + 4, Y + 28  # page TOPLEFT
    canvas.text(px + 74, py + 12, "Commissions Forever", wowmock.FONTS["GameFontNormalLarge"])
    wowmock.search_box(canvas, px + 22, py + 48, 250, instructions="" if query else "Search")
    if bag_only:
        canvas.text(
            px + 288,
            py + 52,
            "Install QuestieDB to see your active turn-ins.",
            wowmock.FONTS["GameFontDisableSmall"],
            width=350,
        )
    if query:
        canvas.text(
            px + 22 + 16,
            py + 48,
            query,
            wowmock.FONTS["GameFontHighlight"],
            box_height=20,
        )
    ix, iy = px + 14, py + 78
    iw, ih = WIDTH - 8 - 28, HEIGHT - 32 - 78 - 44
    canvas.draw(ui.atlas("common-insideframe"), ix + 2, iy + 2, iw - 4, ih - 4)
    columns = re.findall(r'\{ L\["(Material|Turn-in|Have|Need)"\], (\d+), (\d+) \}', SOURCE)
    for label, offset, width in columns:
        canvas.text(ix + int(offset), iy + 10, label, wowmock.FONTS["GameFontNormalSmall"], width=int(width))
    if not rows:
        canvas.text(ix + 12, iy + 42, "No tracked materials found", wowmock.FONTS["GameFontDisableSmall"], width=560)
    for index, row in enumerate(rows):
        # Scroll content TOPLEFT (4,-32), each row TOPLEFT (4,-index*ROW_HEIGHT).
        rx, ry = ix + 8, iy + 32 + index * ROW_HEIGHT
        row_atlas(canvas, ui, "common-button-list-large", rx, ry, ROW_WIDTH, ROW_HEIGHT)
        item = ui.item(row["itemID"])
        canvas.draw(ui.texture(item.icon), rx + 4, ry + 3, 24, 24)
        for offset, text, font, width in [
            (36, item.name, "GameFontHighlight", 218),
            (260, row["source"], "GameFontHighlightSmall", 170),
            (440, str(row["count"]), "GameFontHighlight", 64),
            (510, "-" if row["need"] is None else str(row["need"]), "GameFontHighlight", 64),
        ]:
            canvas.text(rx + offset, ry + 8, text, wowmock.FONTS[font], width=width)
    view_height = ih - 36
    content_height = max(len(rows) * ROW_HEIGHT, 1)
    wowmock.minimal_scrollbar(
        canvas,
        ix + iw - 22,
        iy + 32,
        view_height,
        visible=min(1, view_height / content_height),
    )
    bx, by = px + WIDTH - 8 - 14 - 190, Y + HEIGHT - 4 - 10 - 24
    wowmock.ui_panel_button(canvas, bx, by, 190, 24, "Open turn-in route")
    layout = {
        "frame": {"x": X, "y": Y, "w": WIDTH, "h": HEIGHT},
        "widgets": [
            {"name": "search", "role": "input", "x": px + 22, "y": py + 48, "w": 250, "h": 20},
            {"name": "ledger", "role": "list", "x": ix, "y": iy, "w": iw, "h": ih},
            {"name": "route", "role": "button", "x": bx, "y": by, "w": 190, "h": 24},
            {"name": "page tab", "role": "tabs", "x": X + WIDTH, "y": Y + 116, "w": 55, "h": 55},
        ],
    }
    return canvas, layout


UI_ART_BUILD = "1.60.1.70124"


def main():
    ui = wowmock.Ui(build=UI_ART_BUILD, scale=2)
    output = ROOT / "docs" / "screenshots"
    output.mkdir(parents=True, exist_ok=True)
    variants = {
        "window.png": window(ui),
        "window-search.png": window(ui, query="Favor"),
        "window-bags.png": window(ui, bag_only=True),
    }
    scene_layouts = {}
    for name, (canvas, layout) in variants.items():
        wowmock.scene(ui, [(canvas, 0, 0)]).save(output / name)
        layout["canvas"] = {"width": canvas.width, "height": canvas.height, "scale": ui.scale}
        scene_layouts[name] = layout
        print(output / name)
    lead = scene_layouts["window.png"]
    manifest = {
        "canvas": lead["canvas"],
        "frame": lead["frame"],
        "widgets": lead["widgets"],
        "scenes": list(variants),
        "scene_layouts": scene_layouts,
    }
    (output / "layout.json").write_text(json.dumps(manifest, indent=2) + "\n")


if __name__ == "__main__":
    main()
