"""Focused preparation tests; CORE_REVIEWED_SOURCE must name the reviewed candidate checkout."""

import hashlib
import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

from build_embedded import FOLDER, ROOT, plan, producer

SOURCE = Path(os.environ["CORE_REVIEWED_SOURCE"])
LEGACY = Path(os.environ["CORE_LEGACY_SOURCE"])
CACHE = Path.home() / ".cache/agent-scratch/sweep/wow/commissions-consumer"


class ConsumerTests(unittest.TestCase):
    def test_real_graph(self):
        root = Path(tempfile.mkdtemp(prefix="actual-consumer-", dir=CACHE))
        files = plan(SOURCE, "1.12.1")
        original = (ROOT / (FOLDER + ".toc")).read_text()
        toc = files[FOLDER + ".toc"].decode()
        graph = [line.replace("\\", "/") for line in original.splitlines() if line and not line.startswith("#")]
        actual = [line.replace("\\", "/") for line in toc.splitlines() if line and not line.startswith("#")]
        self.assertEqual(actual[-len(graph) - 1 : -1], graph)
        for line in original.splitlines():
            if line.startswith("##") and not line.startswith(("## Dependencies:", "## OptionalDeps:")):
                self.assertIn(line, toc)
        self.assertNotIn("## Dependencies:", toc)
        self.assertIn("ShortestPathForever, ForeverCore", toc)
        self.assertEqual(files["THIRD_PARTY.md"], (ROOT / "THIRD_PARTY.md").read_bytes())
        self.assertTrue(all(not path.startswith("ForeverCore/") for path in files))
        for path in (ROOT / "media").rglob("*"):
            if path.is_file():
                self.assertEqual(files[path.relative_to(ROOT).as_posix()], path.read_bytes())
        core = producer(SOURCE)
        core.write_bundle(root / FOLDER, files)
        core.check_bundle(root / FOLDER, files)
        manifest = json.loads(files["Libs/ForeverCore/bundle.json"])
        self.assertEqual(set(manifest["files"]), files.keys() - {"Libs/ForeverCore/bundle.json"})
        for name, digest in manifest["files"].items():
            self.assertEqual(hashlib.sha256(files[name]).hexdigest(), digest)
        subprocess.run(
            [
                "python3",
                "tools/build_embedded.py",
                "--core-source",
                str(SOURCE),
                "--core-version",
                "1.12.1",
                "--output",
                str(root / FOLDER),
                "--check",
            ],
            cwd=ROOT,
            check=True,
        )
        core.write_bundle(
            root / "ForeverCore", core.plan(SOURCE, "ForeverCore", "1.12.2", "ForeverCoreDB", b"", standalone=True)
        )
        core.write_bundle(root / "ConsumerB", core.plan(SOURCE, "ConsumerB", "1.12.3", "ConsumerBDB", b""))
        command = ["luajit", "tests/embedded_startup.lua", str(SOURCE), str(root), str(LEGACY)]
        result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True)
        (root / "new-pass.txt").write_text(result.stdout + result.stderr)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        # Reproduce the original synchronous consumer graph against the same
        # canonical embedded runtime: it cannot see a facade before election.
        for name in graph:
            (root / FOLDER / name).write_bytes((ROOT / name).read_bytes())
        (root / FOLDER / "ForeverCoreReady.lua").write_bytes(b"")
        old = subprocess.run(command, cwd=ROOT, capture_output=True, text=True)
        (root / "old-fail.txt").write_text(old.stdout + old.stderr)
        self.assertNotEqual(old.returncode, 0)
        self.assertIn("actual full consumer starts", old.stderr)
        # Restore the passing artifact for independent review.
        for name, data in files.items():
            (root / FOLDER / name).write_bytes(data)
        core.check_bundle(root / FOLDER, files)
        print("retained evidence:", root)


if __name__ == "__main__":
    unittest.main()
