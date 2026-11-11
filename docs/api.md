# CommissionsForever.API

Other addons read Commissions Forever's commission materials, its live quest objectives, its turn-in route and its
completion totals through the global `CommissionsForever.API`. It is version 1, minor 4. On ForeverCore 1.3.2 or later
it is also listed by `ForeverCore.APIKit.Addons()`. The full types are in [`types/API.lua`](../types/API.lua).

Every read that returns a table returns a fresh one that you may keep or change. The reads never write: the only member
that acts outside the addon is `NavigateActiveAssignments()`, which sends a route to Shortest Path Forever.

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
- `minor` 4: `CommissionCategory`, `Materials` and `Subscribe`.

## Functions

- `RequiredMaterials(recipeID, crafts)` returns the raw materials SkillUp Forever needs for `crafts` outputs of that
  recipe, one fresh row per item, or `nil, reason`.
- `CommissionCategory(questID)` returns the turn-in category name a quest belongs to, or `nil, reason`.
- `ActiveObjectives()` returns one fresh row per item objective of every quest in the current log that QuestieDB
  knows, commission or not, or `nil, reason`.
- `Materials()` returns the window's have-versus-need rows as fresh rows, or `nil, reason`.
- `NavigateActiveAssignments()` returns `true` when Shortest Path Forever accepted the active commissions' finishers
  as one route, else `false`. It routes the addon's last refresh, which follows the game's bag and quest log events.
- `Stats()` returns one fresh local activity row.
- `Leaderboard(limit)` returns this character's commission turn-ins ranked with its guild and group, or
  `nil, "invalid"`.
- `Subscribe(callback)` calls `callback(changes)` on the frame after the rows or completions it names changed, and
  returns an unsubscribe function.

## Not ready

A read with nothing to answer returns `nil, reason`, the shape every Forever addon uses
(`ForeverCore.APIKit.NotReady`). The reason says whether to ask again:

| reason | meaning here |
|---|---|
| `"loading"` | QuestieDB is missing or is not yet read as compatible, or the addon has not refreshed yet, so ask again later |
| `"none"` | there is nothing to answer, such as a recipe SkillUp Forever cannot price or a quest that is not a commission |
| `"invalid"` | the argument is wrong, such as a quest ID that is not a positive whole number |

`ActiveObjectives()` returns `nil, "loading"` while QuestieDB is unavailable: an empty list would wrongly say the quest
log asks for no items. `RequiredMaterials()` returns `nil, "none"` when SkillUp Forever is not installed, is too old
to read recipes, or does not know the recipe. Neither read ever returns `"disabled"`.

`Stats()` always returns a table. `Leaderboard()` answers a limit that is not a whole number of zero or more with
plain `nil, "invalid"`: the argument is wrong rather than the data unready, so it is not a not-ready reason.
`CommissionCategory()` answers the same way for a quest ID that is not a positive whole number.

A caller that reads only the first value still sees `nil` when there is no answer. `ActiveObjectives()` is the one
read whose empty answer changed: until minor 3 it returned an empty table while QuestieDB was missing, which looked
like a quest log that asks for nothing. Check the reason when you need to know whether to ask again.

## Required materials

`RequiredMaterials(recipeID, crafts)` plans for `crafts` outputs, one unless given, and returns a fresh array:

| Field | |
|---|---|
| `itemID` | the raw item's ID |
| `count` | how many of it the craft needs |

It forwards to SkillUp Forever's own `RequiredMaterials`, the source of truth for a recipe's reagents. Commissions
Forever stores no recipe data and never invents an ingredient.

## Materials

`Materials()` returns the same have-versus-need rows the Professions page draws, as a fresh array:

| Field | |
|---|---|
| `category` | the turn-in's category name, or for an active quest row the quest's own category from `CommissionCategory()` |
| `itemID` | the material's item ID |
| `have` | how many the bags hold |
| `need` | optional, the quest log's required count when the client has cached the item |
| `questID` | optional, the active quest that asks for the item |

An item an active commission asks for appears once, on that quest's row. It returns `nil, "loading"` before the
addon's first refresh and while QuestieDB is unavailable: an empty list would wrongly say the bags hold nothing and the
log asks for nothing. The internal turn-in table never leaves the addon; every row here is fresh.

## Commission categories

`CommissionCategory(questID)` names the turn-in category a quest belongs to, read through the same QuestieDB
classifier that the window, the turn-in route and the completion record use. It returns the category name, or
`nil, reason`:

- `nil, "none"` when the quest is not a commission.
- `nil, "loading"` while QuestieDB is unavailable, so ask again after it loads.
- `nil, "invalid"` for a quest ID that is not a positive whole number.

The names are the turn-in categories in `Data/TurnIns.lua`: `argentDawn`, `cenarionCircle`, `thoriumBrotherhood`,
`timbermawHold` and `morrowgrain`. A quest's title never decides its category.

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
rows to commissions (with `CommissionCategory()`, `NavigateActiveAssignments()` and inside its window) and does not
guess a quest's requirements from its title.

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

`Subscribe(callback)` reports changes through `ForeverCore.APIKit.Hub`, on the frame after they happen and at most
once per burst:

| channel | meaning |
|---|---|
| `materials` | the have-versus-need rows changed, after a bag or quest log refresh |
| `objectives` | the active quest objectives changed, after a quest log refresh |
| `turnin` | a commission hand-in was recorded |

A refresh that changes none of the rows sends nothing. `changes` is a fresh table each call with only the channels
that changed set to `true` (`{ materials = true }`); read `Materials()` or `ActiveObjectives()` again rather than
replaying the change. `Subscribe` returns an unsubscribe function that is safe to call twice. Only the subscribers
there when a dispatch begins are called. The first subscriber takes the current rows as its baseline, so it hears only
later changes. Until the addon's first refresh has run nothing is reported; the first refresh then reports `materials`
and `objectives` once, because neither list existed before it.

Callers no longer need to read again after every `BAG_UPDATE_DELAYED` and `QUEST_LOG_UPDATE`, though they still may.

## Not in this API

Route guidance, NPC places and the stored completion record are not part of this API: Shortest Path Forever's own API
owns guidance, QuestieDB owns the places, and `Stats()` reports only this character's total. The completions page
explains which hand-ins count: [completion records](completions.md).
