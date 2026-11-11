"""The repository rules over the cases each one was written for."""

import unittest

from tools.repo_rules import unmatched_hashfiles, unused_luacheck_globals

WORKFLOW = "      - with:\n          key: k-${{ hashFiles('tools/*.py', %s) }}\n"


class LuacheckGlobalTest(unittest.TestCase):
    def test_an_entry_nothing_names_fails(self):
        config = '\nread_globals = {\n\t"CreateFrame",\n\t"GetLocale",\n\t"tInvert",\n}\n'
        files = {".luacheckrc": config, "a.lua": 'CreateFrame("Frame")', "Locales/phrases.txt": "GetLocale()"}
        hits = unused_luacheck_globals(files)
        self.assertEqual([hit.split(": ")[0] for hit in hits], [".luacheckrc:5"])


class HashFilesTest(unittest.TestCase):
    def test_a_pattern_matching_nothing_fails(self):
        files = {"tools/gen_a.py": "", "tools/uv.lock": ""}
        self.assertEqual(unmatched_hashfiles({**files, ".github/workflows/ci.yml": WORKFLOW % "'**/*.lock'"}), [])
        dead = unmatched_hashfiles({**files, ".github/workflows/ci.yml": WORKFLOW % "'tools/db2.py'"})
        self.assertEqual([hit.split(": ")[0] for hit in dead], [".github/workflows/ci.yml:2"])


if __name__ == "__main__":
    unittest.main()
