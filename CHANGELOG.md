# Changelog

## [Unreleased]

- **`/cf` in combat opens the window when combat ends.** The game refuses to open a window from an addon in combat, so `/cf` failed with "Interface action failed because of an AddOn". It now says on screen that Commissions opens when combat ends, and opens it then (cjber/commissions-forever#104).
- **Errors stay with you across reloads.** Errors Commissions Forever catches, blocked actions and Lua warnings are now kept across reloads, and `/cf report` shows a report to copy into a bug report (cjber/commissions-forever#103).
- **The Forever Leaderboards period menu works with a gamepad.** With the gamepad interface on, a press on it steps through this week or all time, for your guild and group or for players you've met, instead of opening a game menu that later had the client block `SetPreferredGamepadInteractTarget()` (cjber/forever-core#267).

## [0.2.16] - 2026-11-07

- **The Forever Leaderboards tab wears a game icon.** Its tab uses the client's `INV_Letter_15` letter icon instead of the addon's own logo, so it matches the game's tab set (cjber/forever-core#180).

## [0.2.15] - 2026-11-07
- **Leaderboards show full names.** The Forever Leaderboards rows and tooltips show a player's first name and surname, such as "Dirtyjoke Lovetties", instead of one run-together word or the first name alone. (cjber/forever-core#179)

## [0.2.14] - 2026-11-07
- **The Forever Leaderboards window opens.** `/flb` and `/forever` no longer raise a Lua error on first open: the list's rows now have a fixed height (cjber/forever-core#174).

## [0.2.13] - 2026-11-07
- **The commission leaderboard is part of the shared Forever Leaderboards window.** `/cf leaderboard` and `/cf stats` open that window on the Commissions tab, where you can switch between this week's progress and the all-time total, see your own row pinned in place and read player-reported values without a line of chat. `/flb` opens the window too, and the unit tooltip shows the player's overall place across every installed Forever addon. Sharing is on unless you turn it off, through the window's Share my progress box, `/cf share off` or the Professions page.

## [0.2.12] - 2026-11-07
- **You appear once on leaderboards with a two-part name.** A Forever name like Hel Io no longer shows twice, once as you and once as a reported player with the same value.

## [0.2.11] - 2026-11-06
- **The materials ledger uses the game's own list art.** Its border, rows and row highlight are the client's common list pieces rather than a professions recipe panel, so the page reads as part of the Professions window.

## [0.2.10] - 2026-11-05

- **Suite tooling stays in step with Forever Core.** The vendored shared-file check knows about the new tracker header menu spec, and the vendored changelog check is current. Nothing a player sees changes.

## [0.2.9] - 2026-11-05

- **Suite tooling stays in step with Forever Core.** The vendored menu-scroll check now runs in the required shared job, and the addon's own context menu caps its height and scrolls, so a long list of commissions stays reachable on any screen. The unused dropdown helper is gone from the shared settings page.

## [0.2.8] - 2026-11-05

- **Suite tooling stays in step with Forever Core.** The vendored client load gate picks up Forever Core's newest rules, so this addon refuses a font object the client does not define and a TOC that lists Bindings.xml, the same as the rest of the suite. Nothing a player sees changes.

## [0.2.7] - 2026-11-05

- **The retired merge bot's workflow is gone.** The MergeLoop workflow, its config and its agent skill were removed from the repo, so nothing here waits on a bot that no longer runs. Nothing a player sees changes.

## [0.2.6] - 2026-11-04

- **Suite tooling stays in step with Forever Core.** The vendored shared-file drift check picks up Forever Core's newest rules, so this addon's gate now rejects what the rest of the suite rejects. Nothing a player sees changes.


## [0.2.5] - 2026-11-04

- **The shared asset scanner reads XML too.** Adopted from Forever Core: backdrop file attributes, inline script handlers and texture markup in XML text are checked against the same asset blacklist as Lua.

## [0.2.4] - 2026-11-04

- **Screenshot art keeps its reviewed build.** The renderer records its UI-art pin independently of shared tooling updates, and changing it requires fresh screenshots.

## [0.2.3] - 2026-11-03

- **Compare observed commission turn-ins with your guild and group.** The Professions page has a leaderboard button and a sharing switch. Supported repeat hand-ins count from the game event, while switching sharing off keeps your local history.

### For addon authors

- API v1 minor 2 adds `Stats()` and `Leaderboard(limit)` for fresh local observations and the current client ruleset's bounded guild/group rankings. Other players' totals are player-reported.

## [0.2.2] - 2026-11-03

- **Controls use the Forever asset set.** Buttons use the native gold-bordered family, and CI rejects legacy loose chrome in runtime UI and screenshot renderers.

## [0.2.1] - 2026-11-03

- **The Commissions ledger closes cleanly beside native profession pages.** Item names and active quest requirements refresh when their client data arrives, and Timbermaw turn-ins include both ritual totems.

## [0.2.0] - 2026-11-03

- **Opening Commissions keeps the ledger selected.** A previously used profession is not recast when `/cf` opens the window.
- **Commissions lives in the Professions window.** A native side tab opens a compact, searchable materials ledger with separate Have and Need columns. Native profession pages and other addon pages share the host cleanly.
- **Logistics assignments match their briefing items.** Quests such as Bandages for the Field now appear with their live requirements. Timbermaw deliveries match their quest titles.
- **The Timbermaw catalogue uses Deadwood Ritual Totem.** Logistics briefing documents are no longer mistaken for turn-in materials. Uncached item names refresh when the client receives their data.

- **The turn-in route includes commissions ready to hand in.** Open turn-in route left out every quest whose item objectives were complete, so with everything collected it said no route was available. Finished commissions now route to their turn-in NPC like the rest.
- **A material an active commission asks for is listed once.** It showed twice, as the commission's Have / Need line and again as a plain bag count; only the Have / Need line remains.

## [0.1.6] - 2026-11-02

- **A quest QuestieDB has no name for still counts as a commission.** The addon read the quest log's title from a field the client does not have, so such a quest showed as "Quest" and its number and was left out of the turn-in list. It now uses the quest log's own title.

## [0.1.5] - 2026-11-02

- **Every row shows, however long the list.** The window drew twelve rows and silently dropped the rest; the list now scrolls, so a thirteenth material or objective is never hidden.
- **Each objective keeps its own progress.** Active objectives were paired with the quest log by position, so a reordered or inserted objective showed another item's count. They are now matched by the item the objective names.
- **The window says when QuestieDB is missing.** Without it, active turn-ins cannot be read; a line under the title now says to install QuestieDB instead of the list quietly leaving them out.
- **The window shows its English text.** Its title, route button, empty list line and the no-route chat message were passed `true` instead of their words. Every English phrase is now text.

## [0.1.4] - 2026-10-30

- **The README credits the people behind the addon.** Its Credits section thanks everyone who reports a bug or asks for a feature, and THIRD_PARTY.md's Ideas and contributors table now has the shape the other Forever addons use, with the SkillUp and Shortest Path integrations moved to its Inputs, so a player whose report is built is credited the same way in every addon.

## [0.1.3] - 2026-10-28

- **Adopt the suite's shared editor and Dependabot config.** `.luarc.json` and `.github/dependabot.yml` now match the rest of the suite.

## [0.1.2] - 2026-10-28

- **Check the right addon folder when packaging**: the package gate now verifies the `CommissionsForever` directory instead of a stale `AtlasForever` name, so `tools/check_package.py` no longer fails on a folder that does not exist.

## [0.1.1] - 2026-10-27

- **Keep development files out of the shipped package**: `ruff.toml` (and the duplicated icon entries) no longer reach the release zip, matching the rest of the suite.

## [0.1.0] - 2026-10-27

- **Start the addon scaffold** with the Interface 16001 manifest, shared Sift tooling, a standalone turn-in window, and bag-count tracking for the requested reputation materials.
- **Add a public integration API** for SkillUp Forever recipe materials and multi-stop Shortest Path guidance through active QuestieDB quest finishers.
