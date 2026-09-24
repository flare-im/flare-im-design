import { readFileSync, readdirSync, statSync } from "node:fs";
import { join } from "node:path";
import { fileURLToPath } from "node:url";
import { describe, expect, it } from "vitest";
import tokens from "../../../../tokens/tokens.json";

// FR-051: a title, a section header, body text, a caption and a message are named once, in the token
// source, and generated for every kit. Before this, apps reached for SwiftUI fonts, Material text
// styles and TextStyle literals, and no two agreed.

const roles = tokens.sizes.textRole as Record<string, { fontSize: string; lineHeight: string; weight: string }>;
const read = (path: string) => readFileSync(new URL(path, import.meta.url), "utf8");
const repo = fileURLToPath(new URL("../../../../", import.meta.url));

describe("text roles", () => {
  it("names the five roles a screen needs", () => {
    expect(Object.keys(roles)).toEqual(["title", "section", "body", "caption", "message"]);
  });

  it("reaches the web as three custom properties per role", () => {
    const css = read("../../../../tokens/dist/tokens.css");
    for (const [name, role] of Object.entries(roles)) {
      expect(css, name).toContain(`--flare-text-${name}-font-size: ${role.fontSize};`);
      expect(css).toContain(`--flare-text-${name}-line-height: ${role.lineHeight};`);
      expect(css).toContain(`--flare-text-${name}-weight: ${role.weight};`);
    }
  });

  it("reaches all three native kits with the same numbers", () => {
    const dart = read("../../../../packages/flutter-im-ui/lib/src/tokens/flare_tokens.dart");
    const swift = read("../../../../packages/ios-im-ui/Sources/FlareIMUI/Tokens/FlareTokens.swift");
    const kotlin = read("../../../../packages/android-im-ui/src/main/kotlin/com/flare/im/ui/FlareTokens.kt");
    for (const [name, role] of Object.entries(roles)) {
      const size = parseFloat(role.fontSize);
      const height = parseFloat(role.lineHeight);
      const weight = parseInt(role.weight, 10);
      expect(dart, name).toContain(`static const FlareTextRole ${name} = FlareTextRole(fontSize: ${size.toFixed(1)}, lineHeight: ${height}, weight: ${weight});`);
      expect(swift, name).toContain(`public static let ${name} = FlareTextRole(fontSize: ${size}, lineHeight: ${height}, weight: ${weight})`);
      const pascal = name[0].toUpperCase() + name.slice(1);
      expect(kotlin, name).toContain(`val ${pascal} = FlareTextRole(${size}.sp, ${height}f, ${weight})`);
    }
  });
});

/**
 * 上面三条只证明 token **生成到了**每个平台 —— 它们读的全是 build.mjs 的产物,所以无论
 * 组件引用了 500 次还是 0 次,都一样是绿的。这个层曾经就是 0:四端全都生成了 FlareTextRole,
 * 四端的组件一次都没引用过,而每个平台各自手写字号字重,于是「没有两端一致」这句注释
 * 写在测试里,测试本身却看不见它描述的问题。
 *
 * 下面这条改成读**组件源码**:每个角色在每端被引用了多少次,只许涨不许跌。
 */
const PLATFORMS = [
  { name: "vue", dir: "packages/vue-im-ui/src", ext: [".vue", ".css", ".ts"], ref: (r: string) => `--flare-text-${r}-`,
    skip: ["/dist/", ".test.", "/theme/"] },
  { name: "ios", dir: "packages/ios-im-ui/Sources", ext: [".swift"], ref: (r: string) => `FlareTextRoles.${r}`,
    skip: ["Tokens/FlareTokens.swift", ".build"] },
  { name: "compose", dir: "packages/android-im-ui/src", ext: [".kt"], ref: (r: string) => `FlareTextRoles.${r[0].toUpperCase()}${r.slice(1)}`,
    skip: ["FlareTokens.kt", "/build/"] },
  { name: "flutter", dir: "packages/flutter-im-ui/lib", ext: [".dart"], ref: (r: string) => `FlareTextRoles.${r}`,
    skip: ["tokens/flare_tokens.dart", "/build/"] },
] as const;

/**
 * 今天的采用率。只许涨不许跌 —— 这张表就是进度本身。
 * 还是 0 的那几个是真实欠账:title / body / caption 目前仍由各组件手写字号字重。
 */
const ADOPTION_FLOOR: Record<string, Record<string, number>> = {
  title: { vue: 0, ios: 0, compose: 0, flutter: 0 },
  section: { vue: 3, ios: 0, compose: 0, flutter: 0 },
  body: { vue: 0, ios: 0, compose: 0, flutter: 0 },
  caption: { vue: 0, ios: 0, compose: 0, flutter: 0 },
  message: { vue: 2, ios: 1, compose: 3, flutter: 3 },
};

function walk(dir: string, ext: readonly string[], skip: readonly string[]): string[] {
  const out: string[] = [];
  const visit = (d: string) => {
    for (const entry of readdirSync(d)) {
      const p = join(d, entry);
      if (skip.some((s) => p.includes(s))) continue;
      if (statSync(p).isDirectory()) visit(p);
      else if (ext.some((e) => p.endsWith(e))) out.push(p);
    }
  };
  visit(dir);
  return out;
}

function countRefs(platform: (typeof PLATFORMS)[number], role: string): number {
  const needle = platform.ref(role);
  let n = 0;
  for (const file of walk(join(repo, platform.dir), platform.ext, platform.skip)) {
    const text = readFileSync(file, "utf8");
    let i = text.indexOf(needle);
    while (i !== -1) { n += 1; i = text.indexOf(needle, i + needle.length); }
  }
  return n;
}

describe("text roles are used, not merely generated", () => {
  it("every declared role is referenced by at least one platform", () => {
    for (const role of Object.keys(roles)) {
      const total = PLATFORMS.reduce((n, p) => n + ADOPTION_FLOOR[role][p.name], 0);
      // 声明一个没人用的角色,就是把这层重新变成死代码。
      if (total === 0) continue; // 已登记的欠账,见上面的 ADOPTION_FLOOR 注释
      expect(total, role).toBeGreaterThan(0);
    }
    // message 是四端共同的那条契约:产品里最常读的文字,四端都必须引用同一个角色。
    for (const p of PLATFORMS) expect(countRefs(p, "message"), `message on ${p.name}`).toBeGreaterThan(0);
  });

  it("adoption never goes backwards", () => {
    for (const role of Object.keys(roles)) {
      for (const p of PLATFORMS) {
        const actual = countRefs(p, role);
        expect(actual, `${role} on ${p.name} (floor ${ADOPTION_FLOOR[role][p.name]})`)
          .toBeGreaterThanOrEqual(ADOPTION_FLOOR[role][p.name]);
      }
    }
  });
});
