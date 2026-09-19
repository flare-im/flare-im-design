import assert from "node:assert/strict";
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { pathToFileURL } from "node:url";

import { build } from "esbuild";

const root = new URL("..", import.meta.url);
const entry = new URL("../src/utils/browserDownload.ts", import.meta.url);
const outdir = await mkdtemp(join(tmpdir(), "flare-browser-download-"));
const outfile = join(outdir, "browserDownload.mjs");

try {
  await build({
    entryPoints: [entry.pathname],
    outfile,
    bundle: true,
    format: "esm",
    platform: "browser",
    target: "es2022",
    logLevel: "silent",
    absWorkingDir: root.pathname,
  });

  const { downloadUrlWithFileName, safeDownloadFileName } = await import(pathToFileURL(outfile).href);

  let clicks = [];
  globalThis.document = {
    body: {
      appendChild() {},
    },
    createElement(tag) {
      assert.equal(tag, "a");
      return {
        href: "",
        download: "",
        rel: "",
        style: {},
        click() {
          clicks.push({ href: this.href, download: this.download });
        },
        remove() {},
      };
    },
  };
  globalThis.window = {
    location: { href: "http://localhost:1430/chat" },
    setTimeout() {},
  };

  let fetchCount = 0;
  let lastFetchUrl = "";
  globalThis.fetch = async (url) => {
    fetchCount += 1;
    lastFetchUrl = url;
    return {
      ok: true,
      async blob() {
        return new Blob(["ok"]);
      },
    };
  };
  globalThis.URL = class URLShim extends URL {
    static createObjectURL() {
      return "blob:download";
    }

    static revokeObjectURL() {}
  };

  await downloadUrlWithFileName(
    "http://localhost:1430/__flare-storage/flare-media/media/documents/file.md",
    "file.md",
  );

  assert.equal(fetchCount, 0, "local storage proxy downloads must not fetch");
  assert.deepEqual(clicks, [
    {
      href: "http://localhost:1430/__flare-storage/flare-media/media/documents/file.md",
      download: "file.md",
    },
  ]);

  clicks = [];
  await downloadUrlWithFileName(
    "/__flare-storage/flare-media/media/documents/space%20file.md?X-Amz-Signature=sig",
    "nested/space file.md",
  );

  assert.equal(fetchCount, 0, "relative local storage proxy downloads must not fetch");
  assert.deepEqual(clicks, [
    {
      href: "/__flare-storage/flare-media/media/documents/space%20file.md?X-Amz-Signature=sig",
      download: "space file.md",
    },
  ]);

  clicks = [];
  await downloadUrlWithFileName("https://cdn.example.com/report.md", "unsafe/../report.md");

  assert.equal(fetchCount, 1, "normal HTTP downloads should keep the blob prefetch path");
  assert.equal(lastFetchUrl, "https://cdn.example.com/report.md");
  assert.deepEqual(clicks, [{ href: "blob:download", download: "report.md" }]);
  assert.equal(safeDownloadFileName("../bad:name?.md"), "bad_name_.md");
} finally {
  Reflect.deleteProperty(globalThis, "document");
  Reflect.deleteProperty(globalThis, "window");
  Reflect.deleteProperty(globalThis, "fetch");
  Reflect.deleteProperty(globalThis, "URL");
  await rm(outdir, { recursive: true, force: true });
}
