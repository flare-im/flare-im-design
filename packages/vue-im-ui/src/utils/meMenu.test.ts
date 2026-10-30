import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { afterEach, describe, expect, it, vi } from "vitest";
import { flareIconNameOrFallback } from "../shared/icons";
import { flareMeMenuSections, type FlareMeMenu } from "./meMenu";

interface MenuVector {
  id: string;
  platforms: string[];
  locale: "zh" | "en";
  menu: FlareMeMenu;
  labels?: Record<string, string>;
  summaries?: Record<string, string>;
  expect: { items: { key: string; label: string; icon: string; detail?: string }[] }[];
}
const table = JSON.parse(readFileSync(resolve(__dirname, "../../../../spec/me-menu-vectors.json"), "utf8")) as {
  cases: MenuVector[];
  iconFallback: { cases: { platforms: string[]; name: string; expect: string | null }[] };
};
const LOCALES = { zh: "zh-CN", en: "en-US" } as const;

afterEach(() => vi.restoreAllMocks());

describe("flareMeMenuSections", () => {
  it.each(table.cases.filter((v) => v.platforms.includes("vue")).map((v) => [v.id, v] as const))(
    "follows the shared vector %s",
    (_id, v) => {
      const sections = flareMeMenuSections(v.menu, v.labels, v.summaries, LOCALES[v.locale]);
      expect(sections).toEqual(v.expect.map((section) => ({
        items: section.items.map((item) => ({ ...item, kind: "navigation" })),
      })));
    },
  );

  it("takes the summaries as a Map as well", () => {
    const menu: FlareMeMenu = { items: [{ kind: "plugin", id: "plugin:a", title: "钱包", icon: "wallet" }] };
    expect(flareMeMenuSections(menu, undefined, new Map([["plugin:a", "¥3.00"]]), "zh-CN")[0]?.items[0]?.detail).toBe("¥3.00");
  });
});

describe("flareIconNameOrFallback", () => {
  it.each(table.iconFallback.cases.filter((v) => v.platforms.includes("vue")).map((v) => [JSON.stringify(v.name), v] as const))(
    "resolves %s as the shared vector says",
    (_name, v) => {
      vi.spyOn(console, "warn").mockImplementation(() => {});
      expect(flareIconNameOrFallback(v.name)).toBe(v.expect);
    },
  );

  it("warns once per unknown name in a development build", () => {
    const warn = vi.spyOn(console, "warn").mockImplementation(() => {});
    flareIconNameOrFallback("never-a-glyph-name");
    flareIconNameOrFallback("never-a-glyph-name");
    expect(warn.mock.calls.filter(([text]) => String(text).includes("never-a-glyph-name"))).toHaveLength(1);
  });
});
