"""A maintenance release has no bold lead and still needs a changelog entry the release can publish."""

import contextlib
import io
import unittest

from tools.changelog import check, section

CHANGELOG = """# Changelog

## [Unreleased]

## [0.3.9] - 2026-11-12

<!-- forever-core-sync -->

- Ships with the same shared code as your other Forever addons, so they keep working together.

## [0.3.8] - 2026-11-11

- **Tells you which addon to update.** If another Forever addon you have installed is older than this one, the
  message now names it.
"""


class MaintenanceReleaseTest(unittest.TestCase):
    def test_a_maintenance_entry_above_a_normal_one_is_accepted(self):
        quiet = io.StringIO()
        with contextlib.redirect_stdout(quiet):
            check(CHANGELOG, [])
            check(CHANGELOG, ["0.3.9", "0.3.8"])
        self.assertEqual(
            section(CHANGELOG, "0.3.9"),
            "<!-- forever-core-sync -->\n\n"
            "- Ships with the same shared code as your other Forever addons, so they keep working together.",
        )
        self.assertIn("- **Tells you which addon to update.**", section(CHANGELOG, "0.3.8"))
        self.assertNotIn("- **", section(CHANGELOG, "0.3.9"))


if __name__ == "__main__":
    unittest.main()
