# Completion records

The counter records one supported `QUEST_TURNED_IN` event as one completion for the current character. Two events for the same quest ID count twice, even within one second. It starts with observations made by this version, without estimating older progress from bags or quest history. A crash before SavedVariables are written can lose recent observations.

QuestieDB is required for classification. Through its public contract, the addon requires a repeatable flag, a finisher, positive reputation with the category faction, and matching objective materials or an item that both starts and is provided by that quest. It never identifies completions by a translated title. Missing fields and reader errors record nothing.

Supported categories are Argent Dawn writs, Cenarion Circle logistics assignments, the listed Thorium Brotherhood deliveries, repeatable Timbermaw deliveries, and repeatable Morrowgrain hand-ins. One-time research, soil and ritual-totem quests do not count. Forever commerce work orders lack the required repeatable metadata and are unsupported. QuestieDB objective quantities may be zero or absent. They are not used to classify a completed quest or to estimate how many materials were delivered. Argent Dawn includes the repeatable valor-token hand-in used to obtain a writ.

The record is local to this character. Forever Leaderboards and its guild and group stat sharing are gone, so no totals are sent or received, and nothing is ranked. There is no public server or global ranking.

## Public API

The recorded total is read through `CommissionsForever.API`; [the API page](api.md) lists its functions, the shapes
they return and the reasons a read can return. Completion records stay local.

## Client checks before merge

With QuestieDB installed, run `/etrace`, hand in a supported repeatable quest twice, and confirm each `QUEST_TURNED_IN` carries its quest ID and increases the total from `CommissionsForever.API.Stats()[1].value` by one. Reload and confirm the total survives. Complete a one-time or unrelated quest and confirm it adds nothing.

Check the native profession tabs, scrolling and gamepad navigation at the UI scales you use. No live turn-in is claimed by the headless tests.
