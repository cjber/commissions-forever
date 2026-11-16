"""Prepare a Commissions package from an explicit reviewed Core source, pending release integration.

No pin is updated and no standalone ForeverCore folder is emitted. Run with
--core-source, --core-version and --output (a new CommissionsForever directory).
The version identifies the reviewed candidate for election, not a released claim.
"""

import argparse
import importlib.util
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FOLDER = "CommissionsForever"


def producer(source):
    spec = importlib.util.spec_from_file_location("reviewed_core_producer", source / "tools/build_embedded_core.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def plan(source, version, root=ROOT):
    core = producer(source)
    toc = (root / (FOLDER + ".toc")).read_text()
    graph = [line.strip().replace("\\", "/") for line in toc.splitlines() if line.strip() and not line.startswith("#")]
    entry = b"""local addon, ns, ForeverCore, resources = ...
for _, chunk in ipairs(ns.CommissionsChunks) do
    chunk(addon, ns, ForeverCore)
end
ns.CommissionsChunks = nil
if not ns.broken and (resources.mode ~= "legacy" or (IsLoggedIn and IsLoggedIn())) then
    ns.Start()
end
"""
    files = core.plan(source, FOLDER, version, "CommissionsForeverDB", entry)
    generated = files[FOLDER + ".toc"].decode().splitlines()
    loads = [line for line in generated if line and not line.startswith("#")]
    ready = loads.pop()
    headers = []
    for line in toc.splitlines():
        if not line.startswith("##") or line.startswith("## Dependencies:"):
            continue
        if line.startswith("## OptionalDeps:"):
            line += ", ForeverCore"
        headers.append(line)
    headers.append("## X-Forever-Core-Loader: 1")
    consumer_files = {}
    # Keep consumer metadata and licences separate from the producer-owned subtree.
    for name in ("LICENSE", "THIRD_PARTY.md", "README.md", "CHANGELOG.md"):
        consumer_files[name] = (root / name).read_bytes()
    for path in sorted((root / "media").rglob("*")):
        if path.is_file():
            consumer_files[path.relative_to(root).as_posix()] = path.read_bytes()
    for name in graph:
        data = core.source_file(root, name).read_bytes()
        if not name.endswith(".lua"):
            raise ValueError("Commissions conversion requires review for new non-Lua TOC entries")
        consumer_files[name] = (
            b"local _, host = ...\nhost.CommissionsChunks = host.CommissionsChunks or {}\n"
            b"host.CommissionsChunks[#host.CommissionsChunks + 1] = function(addon, ns, ForeverCore)\n"
            b"local function chunk(...)\n" + data + b"\nend\nreturn chunk(addon, ns)\nend\n"
        )
    consumer_toc = ("\n".join(headers) + "\n\n" + "\n".join(loads + graph + [ready]) + "\n").encode()
    return core.compose_bundle(files, consumer_files, consumer_toc)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--core-source", type=Path, required=True)
    parser.add_argument("--core-version", required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--check", action="store_true", help="verify an existing prepared package exactly")
    args = parser.parse_args()
    if args.output.name != FOLDER:
        parser.error("output must be a new CommissionsForever folder")
    core = producer(args.core_source)
    files = plan(args.core_source, args.core_version)
    if args.check:
        core.check_bundle(args.output, files)
    else:
        core.write_bundle(args.output, files)


if __name__ == "__main__":
    main()
