# About the code

Commissions Forever is a World of Warcraft: Forever addon in Lua 5.1. The files `CommissionsForever.toc` lists
are what the game loads; `tests/*_spec.lua` load them in that order inside a stubbed client.

- Keep every saved variable name and every global the TOC exposes unchanged.
- Generated data, `Libs/` and `tools/forever_tools/` are never edited by hand.
- QuestieDB's public `LibQuestieDB` contract owns NPC and quest data; never copy its database into this repository.
- Taint: never replace a Blizzard global or hook a secure function a spec does not already hook.
- Never use the network, and never start the game, Battle.net, Lutris or Wine. The headless client (forever-core's `wow-forever-addon/in-game.md`) tests the build linked into the game, not this checkout, so in-game checks belong to the agent that ships a change.

## Live roots

Nothing below is dead code, even when no file calls it by name.

- The files `CommissionsForever.toc` lists, loaded in order: `Locales/`, `Data/`, `Core/`, `Integrations/`, `UI/`.
- `## SavedVariables: CommissionsForeverDB`: anything read from it may hold data an older version wrote.
- `CommissionsForever.API` in `Core/API.lua`: the public API other addons call.
- `CommissionsForever_OnAddonCompartmentClick`, `SLASH_COMMISSIONSFOREVER1/2` and their `SlashCmdList` handler: the
  client calls them by name.
- `Integrations/Questie.lua`, `SkillUp.lua` and `ShortestPath.lua`: each reads another addon's public API when it is
  loaded and keeps working when it is not.
- `tools/`: run by CI, `tools/typecheck.sh` and releases, not imported by the addon.
