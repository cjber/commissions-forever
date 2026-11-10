# Completion records

The counter records one supported `QUEST_TURNED_IN` event as one completion for the current character. Two events for the same quest ID count twice, even within one second. It starts with observations made by this version, without estimating older progress from bags or quest history. A crash before SavedVariables are written can lose recent observations.

QuestieDB is required for classification. Through its public contract, the addon requires a repeatable flag, a finisher, positive reputation with the category faction, and matching objective materials or an item that both starts and is provided by that quest. It never identifies completions by a translated title. Missing fields and reader errors record nothing.

Supported categories are Argent Dawn writs, Cenarion Circle logistics assignments, the listed Thorium Brotherhood deliveries, repeatable Timbermaw deliveries, and repeatable Morrowgrain hand-ins. One-time research, soil and ritual-totem quests do not count. Forever commerce work orders lack the required repeatable metadata and are unsupported. QuestieDB objective quantities may be zero or absent. They are not used to classify a completed quest or to estimate how many materials were delivered. Argent Dawn includes the repeatable valor-token hand-in used to obtain a writ.

Sharing is on unless you turn it off. The page checkbox, the window's **Share my progress** box, or `/cf share off` stops sending and receiving, cancels queued sends, and shows only the personal row. Personal recording continues. Received totals already held by another player cannot be recalled. `/cf share on` resumes guild/group sharing. There is no public server or global ranking.

Rankings separate the client's game-mode record ID and Hardcore flag. An unavailable classification keeps the personal view and sends nothing. No game-mode name is guessed from its numeric ID; Self Found is not treated as Ironman. Peer totals are player-reported and are not proof of completion.

## Public API

The recorded total and the leaderboard are read through `CommissionsForever.API`; [the API page](api.md) lists its
functions, the shapes they return and the reasons a read can return. Completion records stay local and are shared
only through the guild and group transport described there.

## Client checks before merge

With QuestieDB installed, run `/etrace`, hand in a supported repeatable quest twice, and confirm each `QUEST_TURNED_IN` carries its quest ID and increases the all-time total on `/cf leaderboard` by one. Reload and confirm the total survives. Complete a one-time or unrelated quest and confirm it adds nothing.

Open `/cf`, toggle sharing off, and confirm the Professions checkbox and the window's **Share my progress** box agree. Hand in another supported quest: the personal total should rise without sending `WFAStats` messages. With two guild/group characters on the same client ruleset, enable sharing and compare their views; disable one and confirm its view returns to its own row. Check another ruleset does not appear.

Check the leaderboard button, checkbox tooltip, native profession tabs, scrolling and gamepad navigation at the UI scales you use. No live turn-in or live cross-client transport is claimed by the headless tests.
