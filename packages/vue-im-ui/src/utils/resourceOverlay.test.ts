import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import {
  flareResourceColors,
  flareResourceColorsFor,
  flareResourceContent,
  flareResourceContents,
  flareResourceEmoji,
  flareResourceLocale,
  flareResourcePlaceholders,
  flareResourceStrings,
  flareResourceStringsFor,
  type FlareResourcePack,
} from "./resourceOverlay";

/**
 * The shared table (`spec/resource-overlay-vectors.json`): what a resource pack may change. The Flutter, SwiftUI and
 * Compose kits run the same file. Its `argb` rows are theirs: Vue writes a colour as it is.
 */
const table = JSON.parse(readFileSync(resolve(__dirname, "../../../../spec/resource-overlay-vectors.json"), "utf8")) as {
  content: { name: string; kind: string; contentJson: string; accepted: boolean }[];
  placeholders: { text: string; expect: string[] }[];
  strings: { name: string; builtIn: Record<string, string>; entries: unknown; expect: Record<string, string> }[];
  locales: { requested: string; available: string[]; expect: string | null }[];
  colors: { name: string; known: string[]; group: unknown; expect: Record<string, string> }[];
  emoji: { name: string; builtInEmoji: string[]; builtInPacks: string[]; packs: unknown; expect: unknown }[];
  fold: {
    name: string;
    locale: string;
    builtIn: Record<string, string>;
    known: string[];
    packs: FlareResourcePack[];
    expect: { strings: Record<string, string>; light: Record<string, string>; dark: Record<string, string> };
  }[];
};

const lookup = (builtIn: Record<string, string>) => (key: string) => new Map(Object.entries(builtIn)).get(key);

describe("resource overlay rules", () => {
  it.each(table.content)("$name", ({ kind, contentJson, accepted }) => {
    expect(flareResourceContent(kind, contentJson) !== null).toBe(accepted);
  });

  it.each(table.placeholders)("reads the placeholders of \"$text\"", ({ text, expect: expected }) => {
    expect(flareResourcePlaceholders(text)).toEqual(expected);
  });

  it.each(table.strings)("$name", ({ builtIn, entries, expect: expected }) => {
    expect(flareResourceStrings(lookup(builtIn), entries)).toEqual(expected);
  });

  it.each(table.locales)("answers $requested from $available", ({ requested, available, expect: expected }) => {
    expect(flareResourceLocale(requested, available) ?? null).toBe(expected);
  });

  it.each(table.colors)("$name", ({ known, group, expect: expected }) => {
    expect(flareResourceColors(new Set(known), group)).toEqual(expected);
  });

  it.each(table.emoji)("$name", ({ builtInEmoji, builtInPacks, packs, expect: expected }) => {
    expect(flareResourceEmoji(builtInEmoji, builtInPacks, packs)).toEqual(expected);
  });

  it.each(table.fold)("$name", ({ locale, builtIn, known, packs, expect: expected }) => {
    const contents = flareResourceContents(packs);
    expect(flareResourceStringsFor(contents.stringPacks, locale, lookup(builtIn))).toEqual(expected.strings);
    expect(flareResourceColorsFor(contents.tokenPacks, "colors", new Set(known))).toEqual(expected.light);
    expect(flareResourceColorsFor(contents.tokenPacks, "dark", new Set(known))).toEqual(expected.dark);
  });

  it("does not count a help pack as ignored", () => {
    const help = { id: "h", kind: "help", packVersion: 1, contentJson: '{"schema":"flare.resource.v1","kind":"help"}' };
    const broken = { id: "b", kind: "strings", packVersion: 1, contentJson: "{" };
    expect(flareResourceContents([help, broken]).ignored).toBe(1);
  });
});
