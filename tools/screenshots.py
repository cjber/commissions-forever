#!/usr/bin/env python3
"""Render the Commissions Forever window with the pinned WoW: Forever UI art."""

import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CORE = Path(os.environ.get("FOREVER_CORE", ROOT.parent / "forever-core"))
sys.path.insert(0, str(CORE / "tools" / "wowmock"))
import wowmock  # noqa: E402


def window(ui):
    panel, x, y = wowmock.basic_panel(ui, "Commissions Forever", 460, 390)
    canvas = ui.canvas(472, 398)
    canvas.paste(panel, 0, 0)
    canvas.text(x + 18, y + 52, "Materials in bags", wowmock.FONTS["GameFontNormal"])
    rows = [
        (11370, 12),  # Dark Iron Ore
        (17012, 4),  # Core Leather
        (17010, 2),  # Fiery Core
        (11040, 6),  # Morrowgrain
    ]
    for index, (item_id, count) in enumerate(rows):
        item = ui.item(item_id)
        top = y + 78 + index * 22
        canvas.text(x + 18, top, f"{item.name}  ×  {count}", wowmock.FONTS["GameFontHighlight"])
    wowmock.ui_panel_button(canvas, x + 150, y + 346, 160, 24, "Open turn-in route")
    return canvas


def main():
    ui = wowmock.Ui(scale=2)
    canvas = window(ui)
    output = ROOT / "docs" / "screenshots" / "window.png"
    output.parent.mkdir(parents=True, exist_ok=True)
    canvas.image.save(output, optimize=False)
    print(output)


if __name__ == "__main__":
    main()
