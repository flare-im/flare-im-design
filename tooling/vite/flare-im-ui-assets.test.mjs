import assert from "node:assert/strict";
import { mkdtempSync, mkdirSync, readdirSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { createServer } from "node:http";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { flareImUiAssets } from "./flare-im-ui-assets.mjs";

test("the Vite asset host serves and copies runtime files without source tools", async t => {
  const root = mkdtempSync(join(tmpdir(), "flare-kit-assets-"));
  t.after(() => rmSync(root, { recursive: true, force: true }));
  const assets = join(root, "assets"); mkdirSync(assets);
  for (const [file, content] of Object.entries({ "manifest.json": "{}", "emoji.webp": "image", "README.md": "docs", "build-manifest.mjs": "source", "fetch-assets.sh": "source", ".hidden.json": "private" })) writeFileSync(join(assets, file), content);
  writeFileSync(join(root, "outside.json"), "private"); symlinkSync(join(root, "outside.json"), join(assets, "link.json"));
  const plugin = flareImUiAssets({ root: assets });
  plugin.configResolved({ root, base: "/social/", build: { outDir: "dist", ssr: false } });
  plugin.writeBundle();
  assert.deepEqual(readdirSync(join(root, "dist/flare-im-ui-assets")).sort(), ["emoji.webp", "manifest.json"]);
  let middleware;
  plugin.configureServer({ middlewares: { use(value) { middleware = value; } } });
  const server = createServer((req, res) => middleware(req, res, () => { res.writeHead(404); res.end(); }));
  await new Promise(resolve => server.listen(0, "127.0.0.1", resolve)); t.after(() => new Promise(resolve => server.close(resolve)));
  const base = `http://127.0.0.1:${server.address().port}/social/flare-im-ui-assets/`;
  const runtime = await fetch(base + "manifest.json"); assert.equal(runtime.status, 200); assert.equal(await runtime.text(), "{}");
  for (const file of ["README.md", "build-manifest.mjs", "fetch-assets.sh", ".hidden.json", "link.json", "%XX"]) assert.equal((await fetch(base + file)).status, 404, file);
});
