# Changelog

## [Unreleased]

- **Forever Leaderboards are gone.** Commissions Forever no longer has a leaderboard tab, a Leaderboard button, or the `/cf leaderboard` and `/cf stats` commands, and guild and group stat sharing has stopped. No totals are sent or received, and the sharing switch is gone with the `/cf share` commands. Your own completed turn-in count stays, and other addons can still read it through the addon's API. Saved shared data is cleared when you log in.

### For addon authors

- `CommissionsForever.API` is version 2, minor 0: `Leaderboard(limit)` is removed along with its guild and group stat sharing. `Stats()` still returns this character's own recorded total.

## [0.3.9] - 2026-11-11

<!-- forever-core-sync -->

- Ships with the same shared code as your other Forever addons, so they keep working together.

## [0.3.8] - 2026-11-11

- **Tells you which addon to update.** If another Forever addon you have installed is older than this one and stops it starting, the message now names that addon, so you know exactly what to update.

## [0.3.7] - 2026-11-11

- **Works again after updating.** Updating to the last version could leave the addon switched off in the game's AddOns list with "ForeverCore: missing", because the update did not bring Forever Core with it. Forever Core now comes inside this addon's download again, from CurseForge, Wago or GitHub alike, so updating is all it takes (cjber/shortest-path-forever#731).

## [0.3.6] - 2026-11-11

<!-- discord-image: docs/screenshots/window.png -->

- **Switching tabs in the Professions window no longer leaves Commissions drawn over another addon's page.** Commissions now gives its side tab and page to Forever Core's shared tab set, which shows one page at a time, places every Forever tab under the game's own, and keeps the window at one width without moving it. (#197, cjber/forever-core#382)

### For addon authors

- `CommissionsForever.API` is now listed by `ForeverCore.APIKit.Addons()`. The addon hands its API table to `ForeverCore.APIKit.Publish` at load on ForeverCore 1.3.2 or later, so a suite-wide reader finds it the same way it finds every other Forever addon's API. Version and minor are unchanged: publishing is not an API change. (#219)

## [0.3.5] - 2026-11-11

- **Forever Core now installs alongside it.** Forever Core is on CurseForge, so the CurseForge app installs and updates it with this addon instead of the addon carrying its own copy. On Wago, install Forever Core from its own page.

## [0.3.4] - 2026-11-10

- **Commissions now finds every commission in your quest log, and only those.** A quest that merely shares part of a turn-in's name is no longer listed or routed, and a commission with an unusual name is now listed and routed. (#200)
- **The addon's own icon is the same everywhere it appears in game.** The Professions side tab now wears the letter icon the Forever Leaderboards tab uses. (#146)

### For addon authors

- `CommissionsForever.API` is minor 4: `CommissionCategory(questID)` names the turn-in category a quest belongs to, `Materials()` returns the window's have-versus-need rows as fresh `{ category, itemID, have, need?, questID? }` rows, and `Subscribe(callback)` reports `materials`, `objectives` and `turnin` changes through `ForeverCore.APIKit.Hub`. `RequiredMaterials` is documented as a forward to SkillUp Forever, the source of truth for a recipe's reagents.

## [0.3.3] - 2026-11-10

- **Opening Commissions no longer causes a blocked-action error.** The game refuses the addon call that opened the Professions window, so the command now tells you on screen to open your profession from your spellbook and shows the Commissions page as soon as you do. (#194)

### For addon authors

- `CommissionsForever.API` is minor 3: a read with nothing to answer now returns `nil, reason` through `ForeverCore.APIKit.NotReady` (`"loading"` while QuestieDB is unavailable, `"none"` when SkillUp Forever has no materials), `ActiveObjectives` no longer answers an empty table while QuestieDB is missing, a read with an answer is unchanged, and `docs/api.md` now lists every function, its answer shape, the reasons each read can return and the minor history.

## [0.3.2] - 2026-11-10

- **Forever Core now comes in the same download.** This addon needs Forever Core, and until Forever Core has its own CurseForge page every Forever addon's download carries a copy of it, so the addon loads with nothing else to install.

## [0.3.1] - 2026-11-10

- **Commissions Forever installs and updates from CurseForge and Wago again.** The 0.3.0 store upload was
  rejected because the addon's package metadata named a CurseForge project that does not exist; Forever Core
  ships from GitHub and Wago, so the package now declares it as a client dependency only. Store installs get
  0.3.0's shared Forever Core tracker, bug report and leaderboards.

## [0.3.0] - 2026-11-10

- **Needs Forever Core.** The shared tracker column, bug report and leaderboards now come from one Forever Core addon that installs with it, so every Forever addon's tracker scale, lock and position stay in step. Your tracker settings carry over.

<!-- discord-image: docs/screenshots/window.png -->

## [0.2.21] - 2026-11-10

- **Profession skill bars no longer show through the Commissions page.** With the Professions overview open underneath, its skill bars drew over the Commissions list. The Commissions page now covers them. (#167)

## [0.2.20] - 2026-11-10

- **Pressing K no longer raises a Lua error.** The Professions side tabs are frames rather than buttons, so Commissions now hooks the tab method that a mouse click and a gamepad press both run instead of a script those tabs do not have. (#158)

## [0.2.19] - 2026-11-10

- **Commissions no longer causes a blocked-action error with a gamepad.** With the gamepad interface on, the game could refuse a gamepad action after you opened or closed the Commissions tab and blame Commissions for it. The tab now opens above the Professions page you have open, and `/cf` opens and closes the Professions window the game's own way. (#147)

## [0.2.18] - 2026-11-09

- **Commissions Forever is on CurseForge and Wago.** Install and update it from either store, or with any addon manager that reads them.

## [0.2.17] - 2026-11-09

- **The Commissions tab opens in combat without touching the protected book page.** The client refuses an addon Hide on the Professions book page because the profession buttons inside it are protected, so the ledger now covers that page and finishes the swap when combat ends (cjber/commissions-forever#114).
- **`/cf` in combat opens the window when combat ends.** The game refuses to open a window from an addon in combat, so `/cf` failed with "Interface action failed because of an AddOn". It now says on screen that Commissions opens when combat ends, and opens it then (cjber/commissions-forever#104).
- **Errors stay with you across reloads.** Errors Commissions Forever catches, blocked actions and Lua warnings are now kept across reloads, and `/cf report` shows a report to copy into a bug report (cjber/commissions-forever#103).

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
