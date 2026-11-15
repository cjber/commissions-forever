# Truncus model-spec trial

The `model` pipeline runs the existing inventory and turn-in model spec on
[Truncus](https://truncus.dev). GitHub Actions continues to check and release
the addon. This pipeline covers only `tests/model_spec.lua`.

The managed `node-24@1` image has no Lua interpreter. The runner downloads
Debian trixie's LuaJIT packages at version `2.1.0+openresty20250117-2`, verifies
their SHA256 digests against `tools/truncus/fetch.lock`, and extracts them into a temporary
directory. These pins come from Debian's
[interpreter](https://packages.debian.org/trixie/amd64/luajit/download) and
[library](https://packages.debian.org/trixie/amd64/libluajit-5.1-2/download)
metadata. This trial runtime differs from the LuaJIT commit in
`tools/toolchain.json`, which continues to govern GitHub Actions.

## Run the trial

With the Truncus CLI installed and signed in, fork the GitHub repository into
a separate Truncus repository, then clone it:

```sh
truncus fork github.com/cjber/commissions-forever truncus.dev/cjber/commissions-forever-dogfood
truncus clone truncus.dev/cjber/commissions-forever-dogfood
cd commissions-forever-dogfood
```

The fork must contain `tools/truncus/` from this change. Bootstrap its root
configuration, then run the check:

```sh
cp tools/truncus/truncus.toml truncus.toml
truncus land -m "Configure model-spec trial" truncus.toml
truncus prove model --logs
truncus rules check --json
```

The pipeline declares five input files. A README edit should reuse its proof;
an edit to `Core/Model.lua` should require a new proof. Use
`truncus propose -m "Test documentation proof reuse" --wait --no-land` to
inspect a proposal without landing it. Proposals require one approval.
Administrators can land `truncus.toml` directly to repair a broken pipeline.

All checked-in trial files live under `tools/` and `docs/`, which the addon
packager already excludes. The root config exists only in the Truncus fork.

The trial needs no game client, ForeverCore checkout, credentials in its
pipeline, GitHub mirror or release integration. A successful run does not
establish in-game behaviour or replace the addon's full CI gate.
