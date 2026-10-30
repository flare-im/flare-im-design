import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import { flarePluralCategory, registerFlareMessages, resolveFlareMessage } from "./messages";

const table = JSON.parse(readFileSync(resolve(__dirname, "../../../../../spec/plural-vectors.json"), "utf8")) as {
  rules: { languages: Record<string, string[]>; default: string };
  cases: { platforms: string[]; locale: string; count: number; one: boolean }[];
  forms: { platforms: string[]; vue: string; locale: "zh" | "en"; count: number; text: string }[];
};
const LOCALES = { zh: "zh-CN", en: "en-US" } as const;

describe("plural category", () => {
  it.each(table.cases.filter((v) => v.platforms.includes("vue")).map((v) => [v.locale, v.count, v] as const))(
    "%s %s",
    (_locale, _count, v) => {
      expect(flarePluralCategory(v.locale, v.count) === "one").toBe(v.one);
    },
  );

  // The natives implement the table in the vectors; the platform's CLDR rules must agree with it.
  it("agrees with the CLDR table the native kits implement", () => {
    const one = (family: string, n: number) =>
      family === "none" ? false
        : family === "is1" ? n === 1
          : family === "is0or1" ? n === 0 || n === 1
            : n % 10 === 1 && n % 100 !== 11;
    const mismatches: string[] = [];
    for (const [family, languages] of Object.entries(table.rules.languages)) {
      for (const language of languages) {
        for (let n = 0; n <= 222; n += 1) {
          if ((flarePluralCategory(language, n) === "one") !== one(family, n)) mismatches.push(`${language} ${n}`);
        }
      }
    }
    expect(mismatches).toEqual([]);
  });
});

describe("plural forms", () => {
  it.each(table.forms.filter((v) => v.platforms.includes("vue")).map((v) => [v.vue, v.locale, v.count, v] as const))(
    "%s in %s for %s",
    (_key, _locale, _count, v) => {
      expect(resolveFlareMessage(LOCALES[v.locale], v.vue, { count: v.count })).toBe(v.text);
    },
  );

  it("reads other without a count, and any CLDR form a registered language carries", () => {
    expect(resolveFlareMessage("en-US", "pluginView.votes")).toBe("{count} votes");
    registerFlareMessages("ru-RU", {
      pluginView: { votes: { one: "{count} голос", few: "{count} голоса", many: "{count} голосов", other: "{count} голоса" } },
    });
    expect(resolveFlareMessage("ru-RU", "pluginView.votes", { count: 21 })).toBe("21 голос");
    expect(resolveFlareMessage("ru-RU", "pluginView.votes", { count: 3 })).toBe("3 голоса");
    expect(resolveFlareMessage("ru-RU", "pluginView.votes", { count: 11 })).toBe("11 голосов");
  });

  it("lets a host's plural forms replace the kit's as a whole", () => {
    registerFlareMessages("en-US", { forward: { moreMessages: { other: "+{count}" } } });
    expect(resolveFlareMessage("en-US", "forward.moreMessages", { count: 1 })).toBe("+1");
    registerFlareMessages("en-US", { forward: { moreMessages: { one: "{count} more message…", other: "{count} more messages…" } } });
  });
});
