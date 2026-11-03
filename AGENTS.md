# Commissions Forever

Commissions Forever tracks repeatable Classic turn-ins, the materials in your bags, and the next NPC stop. It targets WoW: Forever (`Interface 16001`, client folder `_forever_`).

## Commands

```sh
stylua --check .
luacheck .
for spec in tests/*_spec.lua; do luajit "$spec" || exit 1; done
bash tools/typecheck.sh
python3 tools/forever_sim/fetch.py
luajit tools/forever_sim/run.lua
python3 tools/screenshots.py
python3 tools/check_screenshots.py
python3 tools/visual_audit.py
python3 tools/deadcode.py --check
python3 tools/changelog.py --check
python3 .sloppatrol/gate.py --base origin/main
python3 .sloppatrol/agents.py check
```

CI runs the same gate in the jobs `deadcode`, `check`, `python`, `typecheck`, `project-rules` (changelog and the
Sloppatrol gate), `workflows`, `secrets` and `package`, each on every pull request. `tools/deadcode.py` and
`tools/deadcode-allow.txt` are copied from forever-core: change them there.

## Workflow

- Keep Lua compatible with Lua 5.1 and the game's addon sandbox.
- Use only QuestieDB's public `LibQuestieDB` contract for NPC and quest data; never copy its database into this repository.
- Read active quests and inventory from client APIs. Re-scan after quest and bag events.
- Treat each integration as optional. The addon works without QuestieDB, SkillUp Forever, or Shortest Path Forever.
- Never hook Blizzard methods or call protected functions. Do not save frames, functions, userdata, or client tables.
- Run `stylua --check .`, `luacheck .`, every `tests/*_spec.lua` under LuaJIT, and `.sloppatrol/gate.py --base origin/main` plus `.sloppatrol/agents.py check` before proposing changes.
- Render every player-facing UI scene and inspect the PNG at full size. Keep the render reproducible and audit its layout.
- Sign commits with `git commit -S`; do not add `-s` sign-off lines.

## Rules

- Extend Blizzard UI using its frame templates and fonts. Attach the materials ledger to the native Professions window; use native buttons and text.
- Do not invent quest requirements or NPC coordinates. The active quest log and QuestieDB own those values.
- Keep inventory scans event-driven. Do not add idle `OnUpdate` handlers.

## Data and scope

`Data/TurnIns.lua` contains only known item and faction metadata. Quest requirements are read from the active quest log. Do not infer a task's required items from its title. QuestieDB owns NPC names and spawn coordinates; `ShortestPathForever.API.NavigateRoute` owns route guidance.

## Standards

- `wow-forever-addon`: https://github.com/cjber/forever-core/tree/af94fd89610c9128bc11ec07354bd9abafb5dd0/.agents/skills/wow-forever-addon

- For window, widget and asset changes, read [wow-retail-ui-style](https://github.com/cjber/forever-core/tree/af94fd89610c9128bc11ec07354bd9dabafb5dd0/.agents/skills/wow-retail-ui-style), including its asset registry and blacklist.
