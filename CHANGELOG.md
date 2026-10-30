# Changelog

## [Unreleased]

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
