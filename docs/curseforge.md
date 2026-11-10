Commissions Forever keeps repeatable turn-ins in view on its own page in the Professions window. It lists the materials in your bags, shows what each active assignment still needs, and sends the remaining stops to Shortest Path Forever.

QuestieDB, SkillUp Forever and Shortest Path Forever are optional. QuestieDB supplies active quest finishers and their locations; without it the list still counts your materials.

It needs Forever Core, which CurseForge and Wago install with it.

Free, with nothing locked behind it. If it saves you time, you can [sponsor me on GitHub](https://github.com/sponsors/cjber), which takes no fees, or [buy me a coffee on Ko-fi](https://ko-fi.com/cjber). For help and each day's release notes, [join me on Discord](https://discord.gg/FpHugGxRJY).

[![Join me on Discord](https://raw.githubusercontent.com/cjber/commissions-forever/main/docs/discord-button.png)](https://discord.gg/FpHugGxRJY) [![Sponsor me on GitHub](https://raw.githubusercontent.com/cjber/commissions-forever/main/docs/github-sponsors-button.png)](https://github.com/sponsors/cjber) [![Support me on Ko-fi](https://raw.githubusercontent.com/cjber/commissions-forever/main/docs/kofi-button.png)](https://ko-fi.com/cjber)

![Commissions Forever lists turn-in materials with what you have and what each assignment needs](https://raw.githubusercontent.com/cjber/commissions-forever/main/docs/screenshots/window.png)

Active assignments come first, with the count in your bags beside what the quest still asks for.

![Searching the Commissions list for one assignment's materials](https://raw.githubusercontent.com/cjber/commissions-forever/main/docs/screenshots/window-search.png)

The search box narrows the list to one material, assignment or faction.

![Forever Leaderboards on the Commissions tab, showing this week's turn-ins in your guild and group](https://raw.githubusercontent.com/cjber/commissions-forever/main/docs/screenshots/leaderboard.png)

The leaderboard ranks this week's turn-ins in your guild and group, with your own row pinned at the bottom.

![The all-time Commissions leaderboard for players you have met](https://raw.githubusercontent.com/cjber/commissions-forever/main/docs/screenshots/leaderboard-all-time.png)

Switch to the all-time total to compare with players you have met. Others' values are player-reported.

These images are generated previews of the Commissions UI.

## Features

- **One list for turn-ins.** Argent Dawn writs, Cenarion Circle logistics, Thorium Brotherhood materials, Timbermaw Hold items and Morrowgrain research appear together.
- **Live counts.** Bag and quest-log changes refresh the list, and active quest objectives fill in the Need column.
- **Route to the next stop.** Open turn-in route sends the active commission finishers to Shortest Path Forever, which guides you between them.
- **Recipe materials.** When SkillUp Forever is installed, other addons can ask its public API for the raw reagents behind a recipe.
- **Shared leaderboards.** Forever Leaderboards opens on the Commissions tab with this week's progress, the all-time total and peer values marked as player-reported. Sharing is on unless you turn it off.

Completions are counted from real repeat hand-ins from the moment you install the addon. Nothing is backfilled from earlier play, and variable logistics assignments are not guessed from their names.

## Usage

Use `/commissions` or `/cf` to open its page in the Professions window. Choose **Leaderboard**, or use `/cf leaderboard`, to open Forever Leaderboards. `/cf share off` stops sending and receiving totals while keeping your own history, and `/cf share on` resumes; the window's **Share my progress** box does the same.

For a bug report, paste `/cf report`.

<!-- forever-family:start -->

## The Forever addons

Each one works on its own, and they work together when you install more than one.

| Addon | What it does | Issues |
|---|---|---|
| [Shortest Path Forever](https://www.curseforge.com/wow/addons/shortest-path-forever) | Plans journeys on foot, by air, by sea and through portals, with directions in the tracker. | [Issues](https://github.com/cjber/shortest-path-forever/issues) |
| [Adventure Guide Forever](https://www.curseforge.com/wow/addons/adventure-guide-forever) | Suggests quests for your level and routes you from one to the next. | [Issues](https://github.com/cjber/adventure-guide-forever/issues) |
| [SkillUp Forever](https://www.curseforge.com/wow/addons/skillup-forever) | Shows skill-up chances, recipe costs and levelling routes in the Professions window. | [Issues](https://github.com/cjber/skillup-forever/issues) |
| [Legacy Forever](https://www.curseforge.com/wow/addons/legacy-forever) | Shows your unfinished Legacy challenges on the world map and tracks the ones you choose. | [Issues](https://github.com/cjber/legacy-forever/issues) |
| [Tweaks Forever](https://www.curseforge.com/wow/addons/tweaks-forever) | Adds quest automation, rare alerts and merchant options to the game's settings. | [Issues](https://github.com/cjber/tweaks-forever/issues) |
| [Field Guide Forever](https://www.curseforge.com/wow/addons/field-guide-forever) | Keeps a cosmetic journal of the creatures you kill, zone by zone. | [Issues](https://github.com/cjber/field-guide-forever/issues) |
| [Commissions Forever](https://www.curseforge.com/wow/addons/commissions-forever) | Lists your commission turn-ins, the materials in your bags and the next NPC to visit. | [Issues](https://github.com/cjber/commissions-forever/issues) |
| [Macro Assist Forever](https://www.curseforge.com/wow/addons/macro-assist-forever) | Adds a macro window with every macro in one list, a mono editor with live checks, and history. | [Issues](https://github.com/cjber/macro-assist-forever/issues) |

Bug reports, feature requests and pull requests are welcome on each addon's GitHub. Everyone whose report or idea ships is thanked by name in the addon's credits and changelog.

For help, ideas and each day's release notes, join [cjber's Workshop on Discord](https://discord.gg/FpHugGxRJY).

<!-- forever-family:end -->

Data comes from the WoW client and QuestieDB at runtime. The addon does not bundle QuestieDB data.

Source code and issues: [github.com/cjber/commissions-forever](https://github.com/cjber/commissions-forever). Licence: GPL-3.0-or-later.

Built with AI assistance.
