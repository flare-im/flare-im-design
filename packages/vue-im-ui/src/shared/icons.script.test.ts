import { readFileSync } from "node:fs";
import { createContext, runInContext } from "node:vm";
import ts from "typescript";
import { describe, expect, it, vi } from "vitest";

// A host may load the kit's source as a plain script: its SSR checks transpile a component and its imports to
// CommonJS and run them in a vm context, with no bundler in between. `import.meta` is a syntax error there, so the
// icon registry's development-build probe cannot be written with it.
describe("the icon registry as a plain script", () => {
  it("loads without a module loader and resolves names, warning only in a development build", () => {
    const source = readFileSync(new URL("./icons.ts", import.meta.url), "utf8");
    const { outputText } = ts.transpileModule(source, {
      compilerOptions: { target: ts.ScriptTarget.ES2022, module: ts.ModuleKind.CommonJS },
    });
    const glyphs = new Proxy({}, { get: (_target, name) => ({ name: String(name) }) });
    const load = (globals: Record<string, unknown>) => {
      const exports: Record<string, unknown> = {};
      const warn = vi.fn();
      runInContext(outputText, createContext({ exports, require: () => glyphs, console: { warn }, ...globals }));
      return { resolve: exports.flareIconNameOrFallback as (name: string) => string | null, warn };
    };

    // No bundler replaced the build mode and there is no `process`: not a development build.
    const plain = load({});
    expect(plain.resolve("wallet")).toBe("wallet");
    expect(plain.resolve("never-a-glyph-name")).toBe("plugin");
    expect(plain.resolve("  ")).toBeNull();
    expect(plain.warn).not.toHaveBeenCalled();

    const production = load({ process: { env: { NODE_ENV: "production" } } });
    expect(production.resolve("never-a-glyph-name")).toBe("plugin");
    expect(production.warn).not.toHaveBeenCalled();

    const development = load({ process: { env: { NODE_ENV: "development" } } });
    expect(development.resolve("never-a-glyph-name")).toBe("plugin");
    development.resolve("never-a-glyph-name");
    expect(development.warn).toHaveBeenCalledTimes(1);
  });
});
