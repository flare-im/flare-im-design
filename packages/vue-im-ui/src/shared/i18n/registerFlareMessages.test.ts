import { afterEach, describe, expect, it } from "vitest";
import { flareMessages, registerFlareMessages, type FlareMessageTree } from "./messages";

const added: string[] = [];
afterEach(() => {
  for (const locale of added.splice(0)) delete flareMessages[locale];
  delete (flareMessages["zh-CN"] as Record<string, unknown>).pk1HostPatch;
});

describe("registerFlareMessages", () => {
  it("copies a new subtree into a built-in locale instead of keeping the host's object", () => {
    const host: FlareMessageTree = { pk1HostPatch: { title: "宿主文案", nested: { leaf: "叶" } } };
    registerFlareMessages("zh-CN", host);
    const kept = flareMessages["zh-CN"].pk1HostPatch as FlareMessageTree;
    expect(kept).toEqual(host.pk1HostPatch);
    expect(kept).not.toBe(host.pk1HostPatch);
    expect(kept.nested).not.toBe((host.pk1HostPatch as FlareMessageTree).nested);
    // The host edits its tree later: the kit's messages do not change with it.
    ((host.pk1HostPatch as FlareMessageTree).nested as FlareMessageTree).leaf = "改了";
    expect((kept.nested as FlareMessageTree).leaf).toBe("叶");
  });

  it("does not tie two locales together when one tree is registered for both", () => {
    const shared: FlareMessageTree = { common: { hello: "Hej" } };
    added.push("sv-SE", "da-DK");
    registerFlareMessages("sv-SE", shared);
    registerFlareMessages("da-DK", shared);
    registerFlareMessages("da-DK", { common: { hello: "Hej med dig" } });
    expect((flareMessages["sv-SE"].common as FlareMessageTree).hello).toBe("Hej");
    expect((flareMessages["da-DK"].common as FlareMessageTree).hello).toBe("Hej med dig");
    expect((shared.common as FlareMessageTree).hello).toBe("Hej");
  });

  it("still deep-merges into an existing subtree and lets a string replace one", () => {
    added.push("nb-NO");
    registerFlareMessages("nb-NO", { a: { b: "1", c: "2" } });
    registerFlareMessages("nb-NO", { a: { c: "3" } });
    expect(flareMessages["nb-NO"].a).toEqual({ b: "1", c: "3" });
    registerFlareMessages("nb-NO", { a: "flat" });
    expect(flareMessages["nb-NO"].a).toBe("flat");
  });
});
