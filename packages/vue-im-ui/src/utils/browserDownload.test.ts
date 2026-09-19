import { afterEach, beforeEach, describe, expect, it } from "vitest";
import contract from "../../../../spec/security-boundary.json";
import { downloadUrlWithFileName } from "./browserDownload";

// A download URL comes from message content. Before the gate, a hostile image-group
// URL reached `<a href="javascript:…" download>.click()` and ran in the page origin.
// Every hostile vector of spec/security-boundary.json must neither fetch nor navigate.
const hostile = contract.urlVectors.filter((vector) => !vector.safe);

let clicks: string[];
let fetches: string[];

beforeEach(() => {
  clicks = [];
  fetches = [];
  Object.assign(globalThis, {
    document: {
      body: { appendChild() {} },
      createElement: () => ({ href: "", download: "", rel: "", target: "", style: {}, click() { clicks.push(this.target ? `${this.href} (new tab)` : this.href); }, remove() {} }),
    },
    window: { location: { href: "http://localhost:1430/chat" }, setTimeout() {} },
    fetch: async (url: string) => {
      fetches.push(url);
      throw new TypeError("offline");
    },
  });
});

afterEach(() => {
  for (const key of ["document", "window", "fetch"]) Reflect.deleteProperty(globalThis, key);
});

describe("downloadUrlWithFileName", () => {
  it.each(hostile.map((vector) => [vector.id, vector.input]))("refuses %s", async (_id, input) => {
    await expect(downloadUrlWithFileName(input, "file.png")).resolves.toBe(false);
    expect(fetches).toEqual([]);
    expect(clicks).toEqual([]);
  });

  it("still downloads web addresses and the relative storage proxy path", async () => {
    // The fetch fails (no CORS here), so the address opens in a new tab instead of replacing the app.
    await expect(downloadUrlWithFileName("https://cdn.example.com/a.png", "a.png")).resolves.toBe(true);
    await expect(downloadUrlWithFileName("/__flare-storage/media/a.png", "a.png")).resolves.toBe(true);
    expect(fetches).toEqual(["https://cdn.example.com/a.png"]);
    expect(clicks).toEqual(["https://cdn.example.com/a.png (new tab)", "/__flare-storage/media/a.png"]);
  });

  it("accepts a blob this page created and refuses a foreign one", async () => {
    await downloadUrlWithFileName("blob:http://localhost:1430/9b2d", "a.png");
    await downloadUrlWithFileName("blob:https://evil.example/9b2d", "a.png");
    expect(clicks).toEqual(["blob:http://localhost:1430/9b2d"]);
  });
});
