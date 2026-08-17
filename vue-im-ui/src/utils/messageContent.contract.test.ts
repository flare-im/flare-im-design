import { existsSync, readFileSync } from "node:fs";
import { dirname, join, relative, resolve } from "node:path";
import { describe, expect, it } from "vitest";
import { MessageContentType } from "@flare-im/sdk/web";
import { __messageContentTypesForContractTest, messageContentTypeForUi } from "./messageContent";

// 这里的门禁一起替代了一个曾经**只有 flare-social 的 published 构建才能发现**的缺陷：
// 组件库的公共入口可达到对 `@flare-im/sdk` 的值导入，而该依赖被声明为
// optional peer。示例 app 的 vite alias 把它指向同级仓源码，所以本仓永远是绿的。

describe("MessageContentType 契约镜像", () => {
  it("与 SDK 枚举逐位一致（顺序也算契约）", () => {
    // 逐位比对而非集合比对：数值型 contentType 按声明下标解析，
    // 往中间插一个类型会让所有后续类型静默错位。
    expect([...__messageContentTypesForContractTest]).toEqual(Object.values(MessageContentType));
  });

  it("数值下标解析与 SDK 枚举的声明顺序对齐", () => {
    const fromSdk = Object.values(MessageContentType);
    for (let i = 0; i < fromSdk.length; i += 1) {
      expect(messageContentTypeForUi(i)).toBe(fromSdk[i]);
    }
    // 越界回落到 custom，而不是 undefined 漏进模板。
    expect(messageContentTypeForUi(fromSdk.length)).toBe(MessageContentType.Custom);
  });

  it("system / notification 走正常枚举路径（不需要额外 UI 白名单）", () => {
    // 曾有一段注释声称这两个「不在 SDK 枚举里」并为此维护了一份白名单。
    // 枚举其实有它们，白名单是恒冗余的死代码。这条断言把事实钉住。
    expect(messageContentTypeForUi("system")).toBe("system");
    expect(messageContentTypeForUi("notification")).toBe("notification");
  });
});

const packageRoot = resolve(new URL(".", import.meta.url).pathname, "..", "..");
const srcRoot = join(packageRoot, "src");

/**
 * 剥掉注释再扫导入。
 *
 * 不剥的话，**讲述这条规则的注释本身**会被当成违规命中（第一版就这么自我误报了）。
 * 行注释要求 `//` 前不是 `:`，避免把字符串里的 `https://` 当注释起点而吞掉后半行。
 */
function stripComments(source: string): string {
  return source.replace(/\/\*[\s\S]*?\*\//g, " ").replace(/(^|[^:])\/\/[^\n]*/g, "$1");
}

/**
 * 找出对 `@flare-im/sdk`（含子路径）的**值**导入。
 *
 * 放过两种会被 TS 完全擦除、不进产物的形式：
 *   - `import type { … } from "@flare-im/sdk/…"`
 *   - `import { type A, type B } from "@flare-im/sdk/…"`（每个绑定都带 type）
 *
 * 导入子句的字符集刻意排除 `;` 与引号：否则 `[\s\S]*?` 会跨越语句边界，
 * 从上一条 `import { computed } from "vue"` 一直匹配到本条的 `from`，
 * 于是 `import type` 的 type 关键字落在匹配之外 —— 第一版就因此把纯类型导入
 * 报成了违规。
 */
function sdkValueImports(source: string): string[] {
  const offenders: string[] = [];
  const pattern = /import\s+(type\s+)?([^;"']*?)\s*from\s*["'](@flare-im\/sdk(?:\/[^"']+)?)["']/g;
  for (const match of stripComments(source).matchAll(pattern)) {
    const [full, typeKeyword, clause] = match;
    if (typeKeyword) continue;

    const braced = /^\{([\s\S]*)\}$/.exec(clause.trim());
    if (braced) {
      const bindings = braced[1]
        .split(",")
        .map((s) => s.trim())
        .filter(Boolean);
      if (bindings.length > 0 && bindings.every((b) => /^type\s/.test(b))) continue;
    }
    offenders.push(full.replace(/\s+/g, " ").trim());
  }
  return offenders;
}

/** 把一条相对导入解析成磁盘路径（.vue 带扩展名，.ts 可省略，目录走 index.ts）。 */
function resolveRelative(fromFile: string, specifier: string): string | null {
  const base = resolve(dirname(fromFile), specifier);
  const candidates = /\.(ts|vue|js|mts)$/.test(specifier)
    ? [base]
    : [`${base}.ts`, join(base, "index.ts"), `${base}.vue`];
  return candidates.find((c) => existsSync(c)) ?? null;
}

function relativeImportsOf(source: string): string[] {
  const clean = stripComments(source);
  const out: string[] = [];
  // 覆盖 import/export … from "./x" 与 import "./x"（副作用导入）两种形态。
  for (const m of clean.matchAll(/(?:import|export)[\s\S]*?from\s*["'](\.[^"']+)["']/g)) out.push(m[1]);
  for (const m of clean.matchAll(/import\s*["'](\.[^"']+)["']/g)) out.push(m[1]);
  return out;
}

/** 从 exports 映射里取出**非 app 层**的公共入口（app 层允许依赖 SDK）。 */
function publicNonAppEntries(): string[] {
  const manifest = JSON.parse(readFileSync(join(packageRoot, "package.json"), "utf8"));
  const entries: string[] = [];
  for (const [subpath, target] of Object.entries(manifest.exports as Record<string, string>)) {
    if (typeof target !== "string") continue;
    if (target.endsWith(".css")) continue;
    if (subpath.startsWith("./app") || subpath === "./sdk-lab") continue;
    // `./composables/sdk` 是刻意开出来的 SDK 绑定入口，不受此约束。
    if (subpath === "./composables/sdk") continue;
    if (target.includes("*")) continue;
    const abs = resolve(packageRoot, target);
    if (existsSync(abs)) entries.push(abs);
  }
  return entries;
}

describe("公共组件入口不得可达 @flare-im/sdk 的运行时依赖", () => {
  it("从 exports 里每个非 app 入口出发，遍历相对导入图都不碰到 SDK 值导入", () => {
    const entries = publicNonAppEntries();
    // 入口一个都没解析到的话，这条测试会空转成假绿。
    expect(entries.length).toBeGreaterThan(3);

    const seen = new Set<string>();
    const queue = [...entries];
    const violations: string[] = [];

    while (queue.length) {
      const file = queue.pop()!;
      if (seen.has(file)) continue;
      seen.add(file);

      const source = readFileSync(file, "utf8");
      for (const stmt of sdkValueImports(source)) {
        violations.push(`${relative(srcRoot, file)}: ${stmt}`);
      }
      for (const spec of relativeImportsOf(source)) {
        const next = resolveRelative(file, spec);
        if (next && !seen.has(next)) queue.push(next);
      }
    }

    // 遍历要真的走进去了才有意义（组件库有几百个模块）。
    expect(seen.size).toBeGreaterThan(50);

    // package.json 把 @flare-im/sdk 声明为 optional peer。要让这个声明成立，
    // 不装 SDK 的消费方（flare-social 各端用 social wasm 核）必须能用组件库。
    // 需要 SDK 的**值**请放到 src/app/ 下，或走 `./composables/sdk` 入口，
    // 或把取值本地化 + 加一条像上面那样的契约门禁。
    expect(violations).toEqual([]);
  });
});
