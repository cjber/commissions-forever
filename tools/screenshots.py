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

# ForeverCore's UI/Leaderboards.lua shared window.
LB_WIDTH, LB_HEIGHT = 460, 560
LB_X, LB_Y = 26, 26
LB_ROW_HEIGHT = 30
LB_VISIBLE_ROWS = 12
LB_SPACER_HEIGHT = 16

MEDALS = ("challenges-medal-gold", "challenges-medal-silver", "challenges-medal-bronze")
TROPHY = "interface/icons/inv_misc_trophy_argent.blp"
# Every identity surface draws the icon the TOC declares, the same value the addon reads at load.
COMMISSIONS_ICON = TOC_METADATA["X-Forever-Icon"].replace("\\", "/").lower()
if not COMMISSIONS_ICON.endswith(".blp"):
    COMMISSIONS_ICON += ".blp"
CLASS_COLOURS = {
    "WARRIOR": wowmock.rgb("c79c6e"),
    "PALADIN": wowmock.rgb("f58cba"),
    "HUNTER": wowmock.rgb("abd473"),
    "ROGUE": wowmock.rgb("fff569"),
    "PRIEST": wowmock.rgb("ffffff"),
    "SHAMAN": wowmock.rgb("0070de"),
    "MAGE": wowmock.rgb("69ccf0"),
    "WARLOCK": wowmock.rgb("9482c9"),
    "DRUID": wowmock.rgb("ff7d0a"),
}
GREEN = wowmock.rgb("1eff00")
GREY = wowmock.rgb("808080")
WHITE = wowmock.rgb("ffffff")


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


def sample_rows():
    """Use the same sorting, active-assignment merge and bag-only filtering as the client."""
    result = subprocess.run(
        [
            "luajit",
            "-e",
            f"""local ns = {{}}
assert(loadfile("Data/TurnIns.lua"))("CommissionsForever", ns)
local bags = {BAGS}
local objectives = {OBJECTIVES}
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


def window(ui, *, query=""):
    rows = sample_rows()
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
    wowmock.ui_panel_button(canvas, px + WIDTH - 8 - 14 - 132, py + 8, 132, 24, "Leaderboard")
    wowmock.search_box(canvas, px + 22, py + 48, 250, instructions="" if query else "Search")
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
    wowmock.minimal_checkbox(canvas, px + 14, Y + HEIGHT - 4 - 9 - 26, "Share my progress", size=26, checked=True)
    layout = {
        "frame": {"x": X, "y": Y, "w": WIDTH, "h": HEIGHT},
        "widgets": [
            {"name": "leaderboard", "role": "button", "x": px + WIDTH - 8 - 14 - 132, "y": py + 8, "w": 132, "h": 24},
            {"name": "sharing", "role": "input", "x": px + 14, "y": Y + HEIGHT - 4 - 9 - 26, "w": 329, "h": 26},
            {"name": "search", "role": "input", "x": px + 22, "y": py + 48, "w": 250, "h": 20},
            {"name": "ledger", "role": "list", "x": ix, "y": iy, "w": iw, "h": ih},
            {"name": "route", "role": "button", "x": bx, "y": by, "w": 190, "h": 24},
            {"name": "page tab", "role": "tabs", "x": X + WIDTH, "y": Y + 116, "w": 55, "h": 55},
        ],
    }
    return canvas, layout


# The peer rows a Forever Leaderboards board receives: (name, class, weekly progress, all-time total). Aveline is the
# player, with little progress this week and a total high enough to sit inside the all-time list. Helios is a relayed
# peer only the wider "Players you've met" reach includes, and the client has no class for that name.
PEERS = (
    ("Ymira", "PRIEST", 31, 1842),
    ("Brannoc", "WARRIOR", 27, 1510),
    ("Sable", "ROGUE", 24, 1287),
    ("Kestrel", "HUNTER", 22, 1104),
    ("Durn", "PALADIN", 19, 986),
    ("Fen", "MAGE", 17, 901),
    ("Tamsin", "DRUID", 15, 845),
    ("Orrin", "SHAMAN", 13, 733),
    ("Vela", "WARLOCK", 12, 690),
    ("Rook", "ROGUE", 10, 612),
    ("Wren", "PRIEST", 9, 588),
    ("Halvor", "WARRIOR", 8, 501),
    ("Iona", "MAGE", 8, 462),
    ("Aveline", "HUNTER", 7, 971),
)
MET_PEER = ("Helios-Ravencrest", None, 0, 1150)


def leaderboard_rows(scope, reach):
    rows = list(PEERS)
    if reach == "met":
        rows.append(MET_PEER)
    if scope == "week":
        rows.sort(key=lambda row: (-row[2], row[0].lower()))
    else:
        rows.sort(key=lambda row: (-row[3], row[0].lower()))
    result = []
    for rank, (name, class_name, weekly, total) in enumerate(rows, start=1):
        result.append(
            {
                "rank": rank,
                "name": name,
                "class": class_name,
                "value": weekly if scope == "week" else total,
                "total": total,
                "you": name == "Aveline",
            }
        )
    return result


def leaderboard_row(canvas, ui, x, y, width, row, *, weekly):
    if row["you"]:
        canvas.draw(ui.atlas("auctionhouse-ui-row-select"), x, y, width, LB_ROW_HEIGHT)
    if row["rank"] <= 3:
        canvas.draw(ui.atlas(MEDALS[row["rank"] - 1]), x + 12, y + 3, 24, 24)
    else:
        canvas.text(
            x + 12,
            y,
            str(row["rank"]),
            wowmock.FONTS["GameFontHighlight"],
            box_height=LB_ROW_HEIGHT,
            justify="CENTER",
            width=24,
        )
    class_name = row["class"]
    if class_name:
        canvas.draw(ui.atlas("groupfinder-icon-class-" + class_name.lower()), x + 45, y + 4, 22, 22)
        name_colour = CLASS_COLOURS[class_name]
    else:
        name_colour = WHITE
    name = row["name"] + (" (you)" if row["you"] else "")
    canvas.text(
        x + 76,
        y,
        name,
        wowmock.FONTS["GameFontHighlight"],
        name_colour,
        box_height=LB_ROW_HEIGHT,
    )
    value_width = 80
    value_left = x + width - 12 - value_width
    extra_left = value_left - 10 - 90
    if weekly:
        canvas.text(
            extra_left,
            y,
            str(row["total"]) + " total",
            wowmock.FONTS["GameFontHighlightSmall"],
            GREY,
            box_height=LB_ROW_HEIGHT,
            justify="RIGHT",
            width=90,
        )
    canvas.text(
        value_left,
        y,
        ("+" if weekly else "") + str(row["value"]),
        wowmock.FONTS["GameFontHighlight"],
        GREEN if weekly else WHITE,
        box_height=LB_ROW_HEIGHT,
        justify="RIGHT",
        width=value_width,
    )


def leaderboard(ui, *, scope="week", reach="group"):
    weekly = scope == "week"
    rows = leaderboard_rows(scope, reach)
    own_index = next(index for index, row in enumerate(rows, start=1) if row["you"])
    pinned = own_index > LB_VISIBLE_ROWS
    canvas = ui.canvas(LB_WIDTH + LB_X * 2 + 60, LB_HEIGHT + LB_Y * 2)

    rock = ui.texture("interface/framegeneral/ui-background-rock.blp")
    wowmock.tiled(
        canvas,
        rock,
        LB_X + 2,
        LB_Y + 21,
        LB_WIDTH - 4,
        LB_HEIGHT - 23,
        rock.width / ui.scale,
        rock.height / ui.scale,
    )
    canvas.draw(ui.atlas("_UI-Frame-TopTileStreaks"), LB_X + 6, LB_Y + 21, LB_WIDTH - 8, 43)
    wowmock.portrait_frame_art(canvas, LB_X, LB_Y, LB_WIDTH, LB_HEIGHT, TROPHY, "Forever Leaderboards")
    for index, (icon, selected) in enumerate(((TROPHY, False), (COMMISSIONS_ICON, True))):
        wowmock.side_tab(canvas, LB_X + LB_WIDTH - 4, LB_Y + 30 + index * 58, icon, selected=selected)

    canvas.text(
        LB_X + 62,
        LB_Y + 34,
        "Commission turn-ins",
        wowmock.FONTS["GameFontNormalLarge"],
        wowmock.NORMAL,
    )
    canvas.text(
        LB_X + 62,
        LB_Y + 54,
        "Players you've met" if reach == "met" else "Your guild and group",
        wowmock.FONTS["GameFontHighlightSmall"],
    )
    scope_text = "This week" if weekly else "All time"
    wowmock.dropdown(canvas, LB_X + LB_WIDTH - 16 - 140, LB_Y + 60, 140, scope_text, h=24)

    inset_x, inset_y = LB_X + 14, LB_Y + 92
    inset_w, inset_h = LB_WIDTH - 28, LB_HEIGHT - 92 - 74
    marble = ui.texture("interface/framegeneral/ui-background-marble.blp")
    wowmock.tiled(
        canvas,
        marble,
        inset_x + 2,
        inset_y + 2,
        inset_w - 4,
        inset_h - 4,
        marble.width / ui.scale,
        marble.height / ui.scale,
    )
    wowmock.draw_nine_slice(canvas, wowmock.INSET_FRAME_LAYOUT, inset_x, inset_y, inset_w, inset_h)

    canvas.text(inset_x + 12, inset_y + 8, "Rank", wowmock.FONTS["GameFontNormalSmall"], wowmock.NORMAL)
    canvas.text(inset_x + 76, inset_y + 8, "Player", wowmock.FONTS["GameFontNormalSmall"], wowmock.NORMAL)
    canvas.text(
        inset_x + inset_w - 12 - 80,
        inset_y + 8,
        scope_text,
        wowmock.FONTS["GameFontNormalSmall"],
        wowmock.NORMAL,
        justify="RIGHT",
        width=80,
    )
    canvas.draw(ui.atlas("_UI-Frame-InnerTopTile"), inset_x + 4, inset_y + 24, inset_w - 8, 3)

    row_x, row_w = inset_x + 4, inset_w - 28
    scroll_top = inset_y + 26
    scroll_bottom = inset_y + inset_h - (4 + LB_ROW_HEIGHT + LB_SPACER_HEIGHT if pinned else 4)
    list_rows = [row for row in rows if not (pinned and row["you"])]
    # The scroll box clips its content at the frame's bottom, and the inset's own bottom edge draws over it. Keep
    # what is below the clip before the rows draw, then put it back afterwards.
    clip = canvas.px(scroll_bottom)
    below = canvas.image.crop((0, clip, canvas.image.width, canvas.image.height))
    for index, row in enumerate(list_rows):
        y = scroll_top + index * LB_ROW_HEIGHT
        if y >= scroll_bottom:
            break
        leaderboard_row(canvas, ui, row_x, y, row_w, row, weekly=weekly)
    canvas.image.paste(below, (0, clip))
    scroll_height = scroll_bottom - scroll_top
    wowmock.minimal_scrollbar(
        canvas,
        inset_x + inset_w - 20,
        scroll_top,
        scroll_height,
        visible=min(1, scroll_height / max(len(list_rows) * LB_ROW_HEIGHT, 1)),
    )
    if pinned:
        pinned_y = inset_y + inset_h - 4 - LB_ROW_HEIGHT
        own = next(row for row in rows if row["you"])
        leaderboard_row(canvas, ui, row_x, pinned_y, row_w, own, weekly=weekly)
        canvas.text(
            row_x,
            pinned_y - 12,
            "...",
            wowmock.FONTS["GameFontDisableSmall"],
            GREY,
            justify="CENTER",
            width=row_w,
        )

    share_x, share_y = LB_X + 16, LB_Y + LB_HEIGHT - 34 - 32
    canvas.draw(ui.texture("interface/buttons/ui-checkbox-up.blp"), share_x, share_y, 32, 32)
    canvas.draw(ui.texture("interface/buttons/ui-checkbox-check.blp"), share_x, share_y, 32, 32)
    canvas.text(
        share_x + 32 + 2,
        share_y,
        "Share my progress",
        wowmock.FONTS["GameFontHighlight"],
        box_height=32,
    )
    canvas.text(
        LB_X + 18,
        LB_Y + LB_HEIGHT - 14 - 10,
        "Others' values are player-reported.",
        wowmock.FONTS["GameFontDisableSmall"],
        GREY,
    )

    layout = {
        "frame": {"x": LB_X, "y": LB_Y, "w": LB_WIDTH, "h": LB_HEIGHT},
        "widgets": [
            {"name": "metric", "role": "content", "x": LB_X + 62, "y": LB_Y + 34, "w": 200, "h": 24},
            {"name": "scope", "role": "input", "x": LB_X + LB_WIDTH - 16 - 140, "y": LB_Y + 60, "w": 140, "h": 24},
            {"name": "board tabs", "role": "tabs", "x": LB_X + LB_WIDTH - 4, "y": LB_Y + 30, "w": 55, "h": 113},
            {"name": "board", "role": "list", "x": inset_x, "y": inset_y, "w": inset_w, "h": inset_h},
            {"name": "sharing", "role": "input", "x": share_x, "y": share_y, "w": 32, "h": 32},
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
        "leaderboard.png": leaderboard(ui, scope="week", reach="group"),
        "leaderboard-all-time.png": leaderboard(ui, scope="all", reach="met"),
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
