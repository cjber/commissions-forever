#!/usr/bin/env python3
"""Check the screenshot scenes' recorded widgets against their window bounds and one another."""

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MIN_GAP = 8
SIDE_TAB_OVERHANG = 58  # LargeSideTabButtonTemplate sits at the frame's right edge and hangs out.


def audit(layout):
    frame = layout["frame"]
    widgets = layout["widgets"]
    errors = []
    for widget in widgets:
        x, y = widget["x"], widget["y"]
        right, bottom = x + widget["w"], y + widget["h"]
        side_tab = (
            widget["role"] == "tabs"
            and x >= frame["x"] + frame["w"] - 4
            and right <= frame["x"] + frame["w"] + SIDE_TAB_OVERHANG
        )
        if not side_tab and (
            x < frame["x"] or y < frame["y"] or right > frame["x"] + frame["w"] or bottom > frame["y"] + frame["h"]
        ):
            errors.append(f"{widget['name']} lies outside the frame")
    interactive = [widget for widget in widgets if widget["role"] in {"button", "tabs", "input"}]
    for index, first in enumerate(interactive):
        for second in interactive[index + 1 :]:
            dx = max(second["x"] - (first["x"] + first["w"]), first["x"] - (second["x"] + second["w"]), 0)
            dy = max(second["y"] - (first["y"] + first["h"]), first["y"] - (second["y"] + second["h"]), 0)
            if dx == 0 and dy == 0:
                errors.append(f"{first['name']} overlaps {second['name']}")
            elif dx < MIN_GAP and dy < MIN_GAP:
                errors.append(f"{first['name']} and {second['name']} are less than {MIN_GAP} units apart")
    return errors


def main():
    manifest = ROOT / "docs" / "screenshots" / "layout.json"
    data = json.loads(manifest.read_text(encoding="utf-8"))
    scenes = data.get("scene_layouts")
    errors = []
    widgets = 0
    if scenes:
        for name, layout in sorted(scenes.items()):
            errors.extend(f"{name}: {error}" for error in audit(layout))
            widgets += len(layout["widgets"])
    else:
        errors = audit(data)
        widgets = len(data["widgets"])
    for error in errors:
        print(f"visual_audit: {error}")
    print(f"visual_audit: {widgets} widgets, {len(errors)} findings")
    return bool(errors)


if __name__ == "__main__":
    raise SystemExit(main())
