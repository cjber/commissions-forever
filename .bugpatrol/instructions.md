# About the app

Commissions Forever is a World of Warcraft: Forever addon written in Lua 5.1. It cannot run outside the
game client, and you must never start the game. What runs here is its headless test harness: each
`tests/<name>_spec.lua` stubs the client API, loads the addon files the TOC lists, and checks one
feature. Run a spec with `luajit tests/<name>_spec.lua`; a failing spec exits non-zero and prints the
failed assertion. `luacheck <file>` lints a file.

The addon reads quest data only through QuestieDB's public `LibQuestieDB` contract, and treats SkillUp
Forever and Shortest Path Forever as optional. A spec that stubs one of them missing is checking a
supported install, not a broken one.

`python3 tools/visual_audit.py` renders the addon's UI scenes and audits the layout; it is part of the
gate, not a manual step.

Use the specs and `luajit -e` one-liners that load the harness to check what a change claims. Report a
spec that fails, an error that a spec prints, or a behaviour a spec shows that the change does not
intend.

## Sign in

No sign-in.

## Important flows

- The list of repeatable turn-ins you can hand in now, and the next NPC stop for each.
- Bag materials: what a turn-in needs and whether your bags and bank hold it.
- The world map and tracker marks for the next stop.
- Working with QuestieDB missing, and with SkillUp Forever or Shortest Path Forever missing.

## Never do these things

- Never launch the game, Battle.net, Lutris or Wine.
- Never edit, move or delete files.
- Never use the network.
- Never invent quest requirements, NPC coordinates or item IDs: QuestieDB and the quest log own them.
