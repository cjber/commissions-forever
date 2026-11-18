# Commissions Forever

A WoW: Forever addon (`Interface 16001`) that tracks repeatable Classic turn-ins, the materials in your bags and the
next NPC stop, attached to the native Professions window. It requires ForeverCore (tracker column, report window,
error journal, debug log, settings chrome, family page); no shared runtime file is vendored here.

## Gate

```sh
tools/gate.sh            # stylua, luacheck, ruff on tools, every tests/*_spec.lua under LuaJIT, changelog check
tools/gate.sh --changed  # the same, linting only the Lua files changed against origin/main; specs only when a Lua, TOC or XML file changed
bash tools/typecheck.sh  # LuaLS, load graph and the shared lints; run after a signature or type change
```

Set `FOREVER_CORE` to a ForeverCore checkout at `tools/forever-core.txt`'s ref when it is not at `../forever-core`
(always, from a worktree). `python3 tools/doctor.py` checks this machine against the tool pins. CI runs the rest
(screenshots, visual audit, dead code, API docs, repo rules, package, workflows, secrets); never run it whole here.

## Invariants

- Lua 5.1 in the game's sandbox. Never call protected functions or touch Blizzard's Lua state (WFA-38). Never save
  frames, functions, userdata or client tables.
- The materials ledger attaches to the native Professions window. Active quests and inventory come from client APIs,
  re-scanned on quest and bag events. No idle `OnUpdate`.
- NPC names and coordinates come only from QuestieDB's public `LibQuestieDB` contract: never copy its database here.
  Quest requirements come from the active quest log; never invent requirements or coordinates. `Data/TurnIns.lua` holds only item and faction metadata;
  never infer a task's required items from its title. Routes belong to `ShortestPathForever.API.NavigateRoute`.
- QuestieDB, SkillUp Forever and Shortest Path Forever are all optional: the addon works without each.
- The shared runtime comes from the `ForeverCore` global (`ns.core` for this addon's journal, log, report and map
  canvas). `tools/forever_sim/`, `tools/forever_tools/`, `tools/deadcode.py` and `tools/deadcode-allow.txt` are copied from forever-core byte for
  byte: change them there. Generated-data tooling (`refresh-data.yml`, `check_generated.py`) is left out: no
  generated data.
- Player-facing notes go in `changes/<issue>.md`; only the release commit edits `CHANGELOG.md`
  (`python3 tools/changelog.py release X.Y.Z`).
- Render every UI scene (`python3 tools/screenshots.py`) and inspect the PNG at full size.

## Standards

- `repo-standards`: the RS-* requirements every cjber and agent-labs-dev repo meets; its `audit.py` checks this repo.
- `wow-forever-addon`: the WFA-* addon requirements (UI, assets, README and store page, CI and release); wins where
  stricter. UI work also reads `wow-retail-ui-style` in forever-core.
