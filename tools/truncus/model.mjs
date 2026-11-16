// The managed Node image has dpkg-deb but no Lua runtime or compiler.
// Use Debian's LuaJIT only for this trial; tools/toolchain.json governs Actions.
import { createHash } from "node:crypto";
import { execFileSync } from "node:child_process";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const lock = JSON.parse(readFileSync("tools/truncus/fetch.lock", "utf8"));
const runtime = mkdtempSync(join(tmpdir(), "truncus-luajit-"));
try {
  for (const [url, integrity] of Object.entries(lock.fetches)) {
    const response = await fetch(url, { redirect: "error" });
    if (!response.ok) throw new Error(`Download failed: ${response.status} ${url}`);
    const bytes = Buffer.from(await response.arrayBuffer());
    const actual = `sha256-${createHash("sha256").update(bytes).digest("base64")}`;
    if (actual !== integrity) throw new Error(`Integrity mismatch: ${url}`);
    const archive = join(runtime, "package.deb");
    writeFileSync(archive, bytes);
    execFileSync("dpkg-deb", ["--extract", archive, runtime], { stdio: "inherit" });
  }
  const env = { ...process.env, LD_LIBRARY_PATH: join(runtime, "usr/lib/x86_64-linux-gnu") };
  const lua = join(runtime, "usr/bin/luajit");
  execFileSync(lua, ["-v"], { env, stdio: "inherit" });
  execFileSync(lua, ["tests/model_spec.lua"], { env, stdio: "inherit" });
} finally {
  rmSync(runtime, { recursive: true, force: true });
}
