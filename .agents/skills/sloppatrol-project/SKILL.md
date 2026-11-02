---
name: sloppatrol-project
description: "Project profile for Sloppatrol in Commissions Forever: the exact quality-gate and evidence commands, live roots that must never be deleted as dead code, exclusions, conventions and risk order. Load before running Sloppatrol or any code-quality, cleanup or dead-code work in this repository."
---

# Sloppatrol project profile: Commissions Forever

Commissions Forever is a World of Warcraft addon for the WoW: Forever client (Classic content on the
mainline 12.x UI/API, `## Interface: 16001`). It tracks repeatable Classic turn-ins, the materials in
the player's bags and the next NPC stop. It runs in the game's Lua 5.1 sandbox with no `require`: the
client loads the files `CommissionsForever.toc` lists, in that order, and each file receives
`local addonName, ns = ...`. It ships as a zip built by the BigWigs packager (`.pkgmeta`) on a `v*` tag.

## Gate

Run from the repository root. All must pass before and after any audit slice.

| Step | Command | Pass means |
|---|---|---|
| Format | `stylua --check .` | exit 0 (StyLua 2.5.2, `stylua.toml`) |
| Lint | `luacheck .` | `0 warnings / 0 errors` |
| Tests | `for s in tests/*_spec.lua; do luajit "$s" \|\| exit 1; done` | exit 0 |
| Types and tool checks | `bash tools/typecheck.sh` | vendored `forever_tools` match their manifest; editorconfig, family, locale and secret lints pass |
| Screenshots | `python3 tools/check_screenshots.py && python3 tools/visual_audit.py` | exit 0 |
| Secrets | `gitleaks git --redact --no-banner .` | `no leaks found` |
| Project rules | `python3 .sloppatrol/gate.py --base origin/main && python3 .sloppatrol/agents.py check` | exit 0 |

CI (`.github/workflows/ci.yml`) runs all of these in its `check` and `secrets` jobs; `lint.yml` and
`test.yml` run luacheck and the specs on their own. There is no ast-grep rule set.

The specs are a headless harness, not the game client. Each `loadfile`s the file under test with its
own stub `ns`: `model_spec` (Core/Model.lua's inventory rows), `api_spec` (Core/API.lua over stub
SkillUp and Questie integrations), `questie_spec` (Integrations/Questie.lua against a stub
`LibQuestieDB`) and `locale_spec` (every enUS phrase is text). UI/Window.lua, the slash commands and
event handling are verified in game and through the rendered screenshots only.

## Evidence

On-demand tools for audits. Output is candidates, never verdicts.

| Concern | Command | Known false positives |
|---|---|---|
| Unused globals and locals | `luacheck .` | none at setup |
| Duplication | `npx --yes jscpd@4 --silent --reporters json --output .sloppatrol/runs/evidence/jscpd .` | the vendored `tools/forever_tools` and `.agents/skills/wow-forever-addon` copies |
| Layout | `python3 tools/visual_audit.py` | none at setup |

## Live roots

Things reached indirectly. The dead-code lens must treat these as referenced.

- `CommissionsForever.toc` file list: the client loads `Locales/`, `Data/`, `Core/`, `Integrations/` and `UI/` files in that order; nothing `require`s them.
- `## SavedVariables: CommissionsForeverDB`: persisted per account; anything read from it may hold data written by older versions.
- `CommissionsForever.API` (Core/API.lua): the public API other addons call.
- `CommissionsForever_OnAddonCompartmentClick`: called by the client by name from the TOC.
- `SLASH_COMMISSIONSFOREVER1/2` and their `SlashCmdList` handler: the `/commissions` and `/cf` commands.
- Optional integrations (`Integrations/Questie.lua`, `SkillUp.lua`, `ShortestPath.lua`): each reads another addon's public API when it is loaded and must keep working when it is not.
- `tools/`: run by CI, `tools/typecheck.sh` and releases, not imported by the addon.

## Model-read text

`.agents/skills/wow-forever-addon/` is a copy of forever-core's standards skill, and `AGENTS.md` and
this file are read by agents. Audits propose changes to them as `decide`; the producer is forever-core.

## Human documentation

`README.md`, `CHANGELOG.md` and the store pages are player-facing. `Locales/enUS.lua` holds every phrase a
player reads; audits propose wording, never change it.

## Zones

How each part of the tree is reviewed. Unlisted paths are `production`.

| Path | Zone | Reason |
|---|---|---|
| `tests/` | test | LuaJIT specs |
| `tools/` | script | CI, release and screenshot helpers |
| `tools/forever_tools/`, `.agents/skills/wow-forever-addon/`, `.sloppatrol/gate.py`, `.sloppatrol/agents.py` | vendor | pinned copies; change the producer |
| `.github/`, `.luacheckrc`, `stylua.toml`, `.pkgmeta` | config | |
| `README.md`, `CHANGELOG.md`, `AGENTS.md`, `docs/` | docs | |
| `media/` | generated | icon renders |

## Conventions

- Lua 5.1 only, no hooks on Blizzard methods and no protected calls; nothing saved may hold frames, functions or client tables.
- Quest requirements come from the active quest log and NPC data from QuestieDB's public `LibQuestieDB`; `Data/TurnIns.lua` holds only item and faction metadata.
- Inventory scans are event-driven; no idle `OnUpdate`.

## Risk order

Audit slices from lowest to highest risk:

1. `tools/`: not shipped; output is diffable.
2. `tests/`: harness only.
3. `Core/Model.lua`, `Data/TurnIns.lua`: pure lookups, under test.
4. `Locales/enUS.lua`: player copy; proposals only.
5. `Integrations/`: other addons' APIs, optional at run time.
6. `Core/Core.lua`, `Core/API.lua`: events, SavedVariables and the public API.
7. `UI/Window.lua`: the largest, most stateful file, verified only in game and in screenshots.

## Settled

Shapes that look like defects here but are not. Reviewers and verifiers read this before raising a
finding; audits add an entry when verifiers keep dismissing the same shape for the same reason.

## Anti-patterns

Recurring judgment defects; check new code for them.

## Project rules and lenses

- Rules: none yet.
- Lenses: none yet.
