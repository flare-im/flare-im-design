import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import { flareIdTail, type FlareDisplayName } from "../shared/contracts/display-name";
import { flarePluginFallbackName } from "../shared/contracts/plugin-ui";
import { resolveFlareMessage } from "../shared/i18n/messages";
import { flareDisplayNameText } from "./displayName";

const vectors = JSON.parse(readFileSync(resolve(__dirname, "../../../../spec/display-name-vectors.json"), "utf8")) as {
  idTail: Array<{ id: string; input: string; output: string }>;
  text: Array<{ id: string; name: FlareDisplayName; text: Record<"zh-CN" | "en-US", string> }>;
};
const locales = ["zh-CN", "en-US"] as const;

describe("display names (spec/display-name-vectors.json)", () => {
  it("keeps every case the other kits run", () => {
    expect(vectors.idTail.length).toBeGreaterThanOrEqual(12);
    expect(vectors.text.length).toBeGreaterThanOrEqual(24);
  });

  it.each(vectors.idTail.map((v) => [v.id, v] as const))("idTail: %s", (_, v) => {
    expect(flareIdTail(v.input)).toBe(v.output);
    // The plugin view's name for a user it could not resolve is the same tail.
    expect(flarePluginFallbackName(v.input)).toBe(v.output);
  });

  it.each(vectors.text.flatMap((v) => locales.map((locale) => [`${v.id} ${locale}`, v, locale] as const)))(
    "text: %s",
    (_, v, locale) => {
      expect(flareDisplayNameText(v.name, locale)).toBe(v.text[locale]);
      // A translator (useFlareI18n's t) reads the same messages.
      expect(flareDisplayNameText(v.name, (key, params) => resolveFlareMessage(locale, key, params))).toBe(v.text[locale]);
    },
  );

  it("reads a host's own words through its translator", () => {
    const own = (key: string, params?: Record<string, string | number>) =>
      key === "displayName.user" ? `访客 ${params?.idTail}` : resolveFlareMessage("zh-CN", key, params);
    expect(flareDisplayNameText({ kind: "unnamed", entity: "person", idTail: "9876" }, own)).toBe("访客 9876");
  });

  it("never writes a name's braces as a placeholder", () => {
    const name: FlareDisplayName = { kind: "members", names: ["{count}", "{names}"], total: 5 };
    expect(flareDisplayNameText(name, "en-US")).toBe("{count}, {names} and 2 others");
  });
});
