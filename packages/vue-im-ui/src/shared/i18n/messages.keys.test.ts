import { readdirSync, readFileSync, statSync } from "node:fs";
import { join, relative } from "node:path";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";
import { flareMessages } from "./messages";

const srcRoot = fileURLToPath(new URL("../..", import.meta.url));

function sourceFiles(dir: string, out: string[] = []): string[] {
  for (const name of readdirSync(dir)) {
    const path = join(dir, name);
    if (statSync(path).isDirectory()) sourceFiles(path, out);
    else if (/\.(vue|ts)$/.test(name) && !/\.test\.ts$/.test(name)) out.push(path);
  }
  return out;
}

function lookup(tree: unknown, key: string): unknown {
  return key.split(".").reduce<unknown>((node, part) => (node && typeof node === "object" ? (node as Record<string, unknown>)[part] : undefined), tree);
}

describe("message catalog", () => {
  // A missing key renders the key itself ("common.loading") as visible or announced text.
  it("defines every literal t() key in both built-in locales", () => {
    const missing: string[] = [];
    for (const file of sourceFiles(srcRoot)) {
      for (const match of readFileSync(file, "utf8").matchAll(/\bt\(\s*["'`]([a-zA-Z]\w*(?:\.\w+)+)["'`]/g)) {
        for (const locale of ["zh-CN", "en-US"]) {
          if (typeof lookup(flareMessages[locale], match[1]) !== "string") missing.push(`${locale} ${match[1]} (${relative(srcRoot, file)})`);
        }
      }
    }
    expect(missing).toEqual([]);
  });
});
