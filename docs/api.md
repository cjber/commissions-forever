# CommissionsForever.API

Other addons read Commissions Forever's commission materials, its live quest objectives, its turn-in route and its
completion totals through the global `CommissionsForever.API`. It is version 1, minor 3. The full types are in
[`types/API.lua`](../types/API.lua).

Every read returns a fresh table that you may keep or change. The reads never write: the only member that acts is
`NavigateActiveAssignments()`, which sends a route to Shortest Path Forever.

`version` changes only when a published member's arguments, result shape or meaning breaks. An addition keeps
`version` at 1 and raises `minor`, so check that the member you want exists before calling it:

```lua
local api = CommissionsForever and CommissionsForever.API
if not (api and api.version == 1) then
	return
end
if type(api.RequiredMaterials) == "function" then
	local materials, reason = api.RequiredMaterials(recipeID, 2)
	if materials then
		for _, row in ipairs(materials) do
			print(("%s x%d"):format(row.itemID, row.count))
		end
	elseif reason == "none" then
		print("SkillUp Forever has no materials for that recipe")
	end
end
```

## Minor history

Reconstructed from `git log -- Core/API.lua`.

- `minor` 1: `RequiredMaterials`, `ActiveObjectives` and `NavigateActiveAssignments`, version 1's first members.
- `minor` 2: `Stats` and `Leaderboard`, alongside the local completion record.
- `minor` 3: each read's not-ready reason (`nil, reason`) through `ForeverCore.APIKit.NotReady`, and the docs page,
  the types and the contract spec that document this API.

## Functions

- `RequiredMaterials(recipeID, crafts)` returns the raw materials SkillUp Forever needs for `crafts` outputs of that
  recipe, one fresh row per item, or `nil, reason`.
- `ActiveObjectives()` returns one fresh row per item objective of every quest in the current log that QuestieDB
  knows, commission or not, or `nil, reason`.
- `NavigateActiveAssignments()` returns `true` when Shortest Path Forever accepted the active commissions' finishers
  as one route, else `false`. It routes the addon's last refresh, which follows the game's bag and quest log events.
- `Stats()` returns one fresh local activity row.
- `Leaderboard(limit)` returns this character's commission turn-ins ranked with its guild and group, or
  `nil, "invalid"`.

## Not ready

A read with nothing to answer returns `nil, reason`, the shape every Forever addon uses
(`ForeverCore.APIKit.NotReady`). The reason says whether to ask again:

| reason | meaning here |
|---|---|
| `"loading"` | QuestieDB is missing or is not yet read as compatible, so ask again after it loads |
| `"none"` | there is nothing to answer, such as a recipe SkillUp Forever cannot price |

`ActiveObjectives()` returns `nil, "loading"` while QuestieDB is unavailable: an empty list would wrongly say the quest
log asks for no items. `RequiredMaterials()` returns `nil, "none"` when SkillUp Forever is not installed, is too old
to read recipes, or does not know the recipe. Neither read ever returns `"disabled"`.

`Stats()` always returns a table. `Leaderboard()` answers a limit that is not a whole number of zero or more with
plain `nil, "invalid"`: the argument is wrong rather than the data unready, so it is not a not-ready reason.

A caller that reads only the first value still sees `nil` when there is no answer. `ActiveObjectives()` is the one
read whose empty answer changed: until minor 3 it returned an empty table while QuestieDB was missing, which looked
like a quest log that asks for nothing. Check the reason when you need to know whether to ask again.

## Materials

`RequiredMaterials(recipeID, crafts)` plans for `crafts` outputs, one unless given, and returns a fresh array:

| Field | |
|---|---|
| `itemID` | the raw item's ID |
| `count` | how many of it the craft needs |

The recipe and its reagents come from SkillUp Forever's own public API; Commissions Forever stores no recipe data and
never invents an ingredient.

## Active objectives

`ActiveObjectives()` returns a fresh array of rows from the current quest log and QuestieDB. A row is one item a
quest asks for:

| Field | |
|---|---|
| `questID` | the log's quest ID |
| `questName` | QuestieDB's name for the quest, or the log's title when QuestieDB has none |
| `itemID` | the item the quest asks for |
| `sourceItemID` | optional, the item that both starts and is provided by the quest |
| `required` | optional, the log's required count, absent until the client has cached the item |
| `finished` | the log's own progress for that item |
| `npcIDs` | fresh finisher NPC IDs, empty when QuestieDB lists none |

It lists every quest in the log that QuestieDB knows and that asks for an item, commission or not: a quest QuestieDB
does not have, or one with only kill objectives, contributes no row. An empty table therefore means nothing in the log
asks for an item, and `nil, "loading"` means QuestieDB could not be read. Commissions Forever itself filters these
rows to commissions (with `NavigateActiveAssignments()`, and inside its window) and does not guess a quest's
requirements from its title.

NPC names and places are not part of this shape; Shortest Path Forever's own API owns route guidance and QuestieDB
owns the places.

## Stats and Leaderboard

`Stats()` returns one fresh local row, not a wire payload:

| Field | |
|---|---|
| `addon` | always `"CommissionsForever"` |
| `metric` | always `"commission_turnin"` |
| `subject` | always `"all"` |
| `value` | this character's supported turn-ins recorded since this version was installed |
| `eventUnix` | optional, the last accepted turn-in's time, absent before the first one |

`Leaderboard(limit)` returns `{ metric, scope, ruleset, sharing, total, rows }`:

| Field | |
|---|---|
| `metric` | always `"commission_turnin"` |
| `scope` | always `"guild_group"` |
| `ruleset` | optional, the client's game-mode record ID and Hardcore flag, absent when the client cannot classify |
| `sharing` | whether this character sends and receives totals |
| `total` | every eligible row, before the limit |
| `rows` | fresh ranked rows, `rank`, `name`, `value`, optional `eventUnix`, and `self` on this character's row |

The default limit is 10, capped at 25. Zero asks for only the personal row, which is kept even below the limit. Peer
values are player reports and are not proof of completion. Only the current client ruleset is compared. The transport
is ForeverCore's bounded `WFAStats` protocol: the supported cumulative total and its last observation time, never
quest titles or inventory. Equal totals use the shared deterministic ordering. No public server or global ranking
exists.

## Change signal

This minor publishes no `Subscribe`. Read again after the game's `BAG_UPDATE_DELAYED` and `QUEST_LOG_UPDATE` events,
or when your own screen needs a fresh answer. A later minor adds the suite's shared subscription hub without changing
any read above.

## Not in this API

Commission classification, have versus need, and the turn-in rows the window draws are still internal. The completions
page explains which hand-ins count: [completion records](completions.md).
