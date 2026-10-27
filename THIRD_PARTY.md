# Third party materials

## Inputs

| Input | Source and pin | Licence | Ships in zip |
|---|---|---|---|
| Quest names, item objectives and NPC locations | Read from the installed QuestieDB public API at runtime; no QuestieDB data is copied. | QuestieDB | No separate data files |
| Item names and bag counts | Read from the WoW client at runtime. | Blizzard client data | No separate data files |
| WoW Forever shared UI mock renderer | `cjber/forever-core/tools/wowmock`, pinned by `tools/forever_tools/MANIFEST.json`. | MIT | No |
| Commissions Forever icon | `media/icon.svg`, rendered from the Forever family icon template. | Commissions Forever, GPL-3.0-or-later | Yes |

## Ideas and contributors

| Source | Contribution |
|---|---|
| Cillian Berragan (@cillian) | Requested the turn-in tracker and the suite-wide setup. |
| Blizzard's WoW client | Quest log, inventory and UI conventions this addon extends. |
| QuestieDB | Runtime quest, item and NPC data. |
| SkillUp Forever | The recipe material API used by addon integrations. |
| Shortest Path Forever | Optional multi-stop navigation. |
