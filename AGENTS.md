# Commissions Forever

Commissions Forever tracks repeatable Classic turn-ins, the materials in your bags, and the next NPC stop. It targets WoW: Forever (`Interface 16001`, `_classic_beta_`).

## Commands

```sh
stylua --check .
luacheck .
for spec in tests/*_spec.lua; do luajit "$spec" || exit 1; done
bash tools/typecheck.sh
python3 tools/screenshots.py
python3 tools/check_screenshots.py
python3 tools/visual_audit.py
python3 .sift/gate.py --base origin/main
python3 .sift/agents.py check
```

## Workflow

- Keep Lua compatible with Lua 5.1 and the game's addon sandbox.
- Use only QuestieDB's public `LibQuestieDB` contract for NPC and quest data; never copy its database into this repository.
- Read active quests and inventory from client APIs. Re-scan after quest and bag events.
- Treat each integration as optional. The addon works without QuestieDB, SkillUp Forever, or Shortest Path Forever.
- Never hook Blizzard methods or call protected functions. Do not save frames, functions, userdata, or client tables.
- Run `stylua --check .`, `luacheck .`, every `tests/*_spec.lua` under LuaJIT, and `.sift/gate.py --base origin/main` plus `.sift/agents.py check` before proposing changes.
- Render every player-facing UI scene and inspect the PNG at full size. Keep the render reproducible and audit its layout.
- Never use `-s` on commits; signing is handled by GitHub.

## Rules

- Extend Blizzard UI using its frame templates and fonts. Keep the standalone window opaque and movable; use native buttons and text.
- Do not invent quest requirements or NPC coordinates. The active quest log and QuestieDB own those values.
- Keep inventory scans event-driven. Do not add idle `OnUpdate` handlers.

## Data and scope

`Data/TurnIns.lua` contains only known item and faction metadata. Quest requirements are read from the active quest log. Do not infer a task's required items from its title. QuestieDB owns NPC names and spawn coordinates; `ShortestPathForever.API.NavigateRoute` owns route guidance.

## Standards

- `wow-forever-addon` — https://github.com/cjber/forever-core/tree/3fd1b7fe109e709c4952bb04622e94d05636585e/.agents/skills/wow-forever-addon
