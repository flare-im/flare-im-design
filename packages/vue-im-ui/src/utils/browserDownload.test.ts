import { afterEach, beforeEach, describe, expect, it } from "vitest";
import contract from "../../../../spec/security-boundary.json";
import {
  downloadUrlWithFileName,
  downloadAuthorizedAttachment,
} from "./browserDownload";

// A download URL comes from message content. Before the gate, a hostile image-group
// URL reached `<a href="javascript:…" download>.click()` and ran in the page origin.
// Every hostile vector of spec/security-boundary.json must neither fetch nor navigate.
const hostile = contract.urlVectors.filter((vector) => !vector.safe);

let clicks: string[];
let fetches: string[];
let savedNames: string[];

beforeEach(() => {
  clicks = [];
  fetches = [];
  savedNames = [];
  Object.assign(globalThis, {
    document: {
      body: { appendChild() {} },
      createElement: () => ({
        href: "",
        download: "",
        rel: "",
        target: "",
        style: {},
        click() {
          clicks.push(this.target ? `${this.href} (new tab)` : this.href);
          savedNames.push(this.download);
        },
        remove() {},
      }),
    },
    window: {
      location: { href: "http://localhost:1430/chat" },
      setTimeout() {},
    },
    fetch: async (url: string) => {
      fetches.push(url);
      throw new TypeError("offline");
    },
  });
});

describe("private administrative attachment download", () => {
  it.each([
    "javascript:alert(1)",
    "http://objects.test/file",
    "https://user:secret@objects.test/file",
    "https://objects.test/file#fragment",
  ])("refuses %s before fetching", async (url) => {
    await expect(
      downloadAuthorizedAttachment(
        url,
        "file.txt",
        new AbortController().signal,
        () => true,
      ),
    ).rejects.toThrow();
    expect(fetches).toEqual([]);
    expect(clicks).toEqual([]);
  });
  it("does not fall back to opening an unauthorized or non-CORS URL", async () => {
    await expect(
      downloadAuthorizedAttachment(
        "https://objects.test/private",
        "file.txt",
        new AbortController().signal,
        () => true,
      ),
    ).rejects.toThrow();
    expect(clicks).toEqual([]);
  });
  it("omits credentials, rejects redirects, and refuses a late scope change", async () => {
    let current = true;
    globalThis.fetch = async (_url, options) => {
      expect(options).toMatchObject({
        credentials: "omit",
        redirect: "error",
        referrerPolicy: "no-referrer",
        cache: "no-store",
      });
      current = false;
      return new Response("private bytes");
    };
    await expect(
      downloadAuthorizedAttachment(
        "https://objects.test/private",
        "file.txt",
        new AbortController().signal,
        () => current,
      ),
    ).rejects.toThrow();
    expect(clicks).toEqual([]);
  });
  it("saves fetched bytes with a safe filename only while the context is current", async () => {
    const originalCreate = URL.createObjectURL;
    let saved: Blob | undefined;
    URL.createObjectURL = (blob) => {
      saved = blob as Blob;
      return "blob:https://console.test/owned-download";
    };
    globalThis.fetch = async () => new Response("exact private bytes");
    try {
      await downloadAuthorizedAttachment(
        "https://objects.test/private",
        "../report.txt",
        new AbortController().signal,
        () => true,
      );
      expect(await saved?.text()).toBe("exact private bytes");
      expect(clicks).toEqual(["blob:https://console.test/owned-download"]);
      expect(savedNames).toEqual(["report.txt"]);
    } finally {
      URL.createObjectURL = originalCreate;
    }
  });
  it("cancels oversized responses without saving anything", async () => {
    let cancelled = false;
    globalThis.fetch = async () =>
      new Response(
        new ReadableStream({
          cancel() {
            cancelled = true;
          },
        }),
        { headers: { "Content-Length": String(129 * 1024 * 1024) } },
      );
    await expect(
      downloadAuthorizedAttachment(
        "https://objects.test/private",
        "file.txt",
        new AbortController().signal,
        () => true,
      ),
    ).rejects.toThrow();
    expect(cancelled).toBe(true);
    expect(clicks).toEqual([]);
  });
});

afterEach(() => {
  for (const key of ["document", "window", "fetch"])
    Reflect.deleteProperty(globalThis, key);
});

describe("downloadUrlWithFileName", () => {
  it.each(hostile.map((vector) => [vector.id, vector.input]))(
    "refuses %s",
    async (_id, input) => {
      await expect(downloadUrlWithFileName(input, "file.png")).resolves.toBe(
        false,
      );
      expect(fetches).toEqual([]);
      expect(clicks).toEqual([]);
    },
  );

  it("still downloads web addresses and the relative storage proxy path", async () => {
    // The fetch fails (no CORS here), so the address opens in a new tab instead of replacing the app.
    await expect(
      downloadUrlWithFileName("https://cdn.example.com/a.png", "a.png"),
    ).resolves.toBe(true);
    await expect(
      downloadUrlWithFileName("/__flare-storage/media/a.png", "a.png"),
    ).resolves.toBe(true);
    expect(fetches).toEqual(["https://cdn.example.com/a.png"]);
    expect(clicks).toEqual([
      "https://cdn.example.com/a.png (new tab)",
      "/__flare-storage/media/a.png",
    ]);
  });

  it("accepts a blob this page created and refuses a foreign one", async () => {
    await downloadUrlWithFileName("blob:http://localhost:1430/9b2d", "a.png");
    await downloadUrlWithFileName("blob:https://evil.example/9b2d", "a.png");
    expect(clicks).toEqual(["blob:http://localhost:1430/9b2d"]);
  });
});
