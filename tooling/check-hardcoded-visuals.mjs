#!/usr/bin/env node
// 四端源码里「字面值恰好等于某个 token 值」的硬编码棘轮。
//
// 规则刻意保守：只报**精确等于 token 值**的字面颜色 / 间距 / 圆角 / 字号 / 图标尺寸，
// 因为这些一定应该改成引用 token(值一样却不引用,token 一改就漂移);其它字面量
// (发丝线 1、示意色、派生比例)不管。与 tooling/hardcoded-visuals-baseline.json 比,
// 只允许下降;`--baseline` 重写基线,`--list` 看 Top 文件。
import { readFileSync, readdirSync, statSync, writeFileSync, existsSync } from "node:fs";
import { dirname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, "..");
const baselinePath = join(here, "hardcoded-visuals-baseline.json");
const tokens = JSON.parse(readFileSync(join(root, "tokens/tokens.json"), "utf8"));

// ── token 值集合 ────────────────────────────────────────────────────────
const colorValues = new Set();
const collect = (o) => { for (const v of Object.values(o)) typeof v === "string" ? colorValues.add(v.toLowerCase().replace(/\s+/g, "")) : collect(v); };
collect(tokens.colors); collect(tokens.dark.colors);
const hexSet = new Set([...colorValues].filter((v) => v.startsWith("#")).map((v) => v.slice(1)));
const px = (o) => Object.values(o).map((v) => parseFloat(v)).filter((n) => Number.isFinite(n) && n > 2);
const spacing = new Set(px(tokens.sizes.spacing));
const radius = new Set(px(tokens.sizes.radius).filter((n) => n < 999));
const fontSize = new Set(px(tokens.sizes.fontSize));
const iconSize = new Set(px(tokens.sizes.iconSize));
const control = new Set([tokens.sizes.layout.touchTarget, tokens.sizes.layout.avatarSize].map(parseFloat));
const has = (set, s) => set.has(parseFloat(s));

// ── 目标目录 ────────────────────────────────────────────────────────────
const TARGETS = {
  vue: { dirs: ["packages/vue-im-ui/src/components", "packages/vue-im-ui/src/design-system/styles"], ext: [".vue", ".css"], skip: [/\.test\.ts$/] },
  flutter: { dirs: ["packages/flutter-im-ui/lib/src/components", "packages/flutter-im-ui/lib/src/primitives"], ext: [".dart"], skip: [] },
  ios: { dirs: ["packages/ios-im-ui/Sources/FlareIMUI/Components", "packages/ios-im-ui/Sources/FlareIMUI/EmojiSticker"], ext: [".swift"], skip: [/Previews\.swift$/] },
  compose: { dirs: ["packages/android-im-ui/src/main/kotlin"], ext: [".kt"], skip: [/FlareTokens\.kt$/, /Previews?\.kt$/] },
};

function walk(dir, ext) {
  const out = [];
  if (!existsSync(dir)) return out;
  for (const n of readdirSync(dir)) {
    const p = join(dir, n);
    if (statSync(p).isDirectory()) out.push(...walk(p, ext));
    else if (ext.some((e) => p.endsWith(e))) out.push(p);
  }
  return out;
}
function stripComments(src) {
  let out = "", i = 0;
  while (i < src.length) {
    const two = src.slice(i, i + 2);
    if (two === "//") { while (i < src.length && src[i] !== "\n") i++; }
    else if (two === "/*") { const e = src.indexOf("*/", i + 2); i = e === -1 ? src.length : e + 2; }
    else if (src.startsWith("<!--", i)) { const e = src.indexOf("-->", i); i = e === -1 ? src.length : e + 3; }
    else out += src[i++];
  }
  return out;
}

// ── 每端规则:返回命中数 ──────────────────────────────────────────────────
const RULES = {
  vue(src) {
    let n = 0;
    // 字面色(不在 var() 兜底位置里的)
    const noFallback = src.replace(/var\([^()]*\)/g, "");
    for (const m of noFallback.matchAll(/#([0-9a-fA-F]{6})\b/g)) if (hexSet.has(m[1].toLowerCase())) n++;
    for (const m of noFallback.matchAll(/rgba?\([^)]*\)/g)) if (colorValues.has(m[0].toLowerCase().replace(/\s+/g, ""))) n++;
    // 间距 / 圆角 / 字号(等于 token 值的 px)
    for (const m of noFallback.matchAll(/\b(padding|margin|gap|border-radius|font-size|width|height|min-height|top|left|right|bottom)(?:-[a-z]+)?\s*:\s*([^;{}]+);/g)) {
      const prop = m[1], vals = m[2].match(/\b(\d+(?:\.\d+)?)px\b/g) ?? [];
      for (const v of vals) {
        if (prop === "border-radius" ? has(radius, v) : prop === "font-size" ? has(fontSize, v) : /width|height/.test(prop) ? (has(control, v) || has(iconSize, v)) : has(spacing, v)) n++;
      }
    }
    return n;
  },
  flutter(src) {
    let n = 0;
    for (const m of src.matchAll(/Color\(0x[0-9a-fA-F]{2}([0-9a-fA-F]{6})\)/g)) if (hexSet.has(m[1].toLowerCase())) n++;
    for (const m of src.matchAll(/EdgeInsets\.(?:all|symmetric|only|fromLTRB)\(([^()]*)\)/g)) for (const v of m[1].match(/\b\d+(?:\.\d+)?\b/g) ?? []) if (has(spacing, v)) n++;
    for (const m of src.matchAll(/BorderRadius\.circular\((\d+(?:\.\d+)?)\)|Radius\.circular\((\d+(?:\.\d+)?)\)/g)) if (has(radius, m[1] ?? m[2])) n++;
    for (const m of src.matchAll(/fontSize:\s*(\d+(?:\.\d+)?)/g)) if (has(fontSize, m[1])) n++;
    for (const m of src.matchAll(/\bsize:\s*(\d+(?:\.\d+)?)/g)) if (has(iconSize, m[1]) || has(control, m[1])) n++;
    return n;
  },
  ios(src) {
    let n = 0;
    for (const m of src.matchAll(/\.padding\((?:\.[a-zA-Z]+,\s*)?(\d+(?:\.\d+)?)\)/g)) if (has(spacing, m[1])) n++;
    for (const m of src.matchAll(/cornerRadius:\s*(\d+(?:\.\d+)?)|\.cornerRadius\((\d+(?:\.\d+)?)\)/g)) if (has(radius, m[1] ?? m[2])) n++;
    for (const m of src.matchAll(/\.system\(size:\s*(\d+(?:\.\d+)?)/g)) if (has(fontSize, m[1]) || has(iconSize, m[1])) n++;
    for (const m of src.matchAll(/spacing:\s*(\d+(?:\.\d+)?)/g)) if (has(spacing, m[1])) n++;
    for (const m of src.matchAll(/\.frame\([^()]*?(?:width|height):\s*(\d+(?:\.\d+)?)/g)) if (has(control, m[1]) || has(iconSize, m[1])) n++;
    return n;
  },
  compose(src) {
    let n = 0;
    for (const m of src.matchAll(/Color\(0x[0-9a-fA-F]{2}([0-9a-fA-F]{6})\)/g)) if (hexSet.has(m[1].toLowerCase())) n++;
    for (const m of src.matchAll(/\b(\d+(?:\.\d+)?)\.dp\b/g)) if (has(spacing, m[1]) || has(radius, m[1]) || has(control, m[1]) || has(iconSize, m[1])) n++;
    for (const m of src.matchAll(/\b(\d+(?:\.\d+)?)\.sp\b/g)) if (has(fontSize, m[1])) n++;
    return n;
  },
};

const args = process.argv.slice(2);
const result = {};
for (const [platform, t] of Object.entries(TARGETS)) {
  const files = t.dirs.flatMap((d) => walk(join(root, d), t.ext)).filter((f) => !t.skip.some((re) => re.test(f)));
  let total = 0; const perFile = {};
  for (const f of files) {
    const c = RULES[platform](stripComments(readFileSync(f, "utf8")));
    if (c) { perFile[relative(root, f)] = c; total += c; }
  }
  result[platform] = { total, files: perFile };
}
if (args.includes("--baseline")) {
  writeFileSync(baselinePath, JSON.stringify(Object.fromEntries(Object.entries(result).map(([p, r]) => [p, r.total])), null, 2) + "\n");
  console.log("baseline written:", Object.entries(result).map(([p, r]) => `${p}=${r.total}`).join(" "));
  process.exit(0);
}
if (args.includes("--list")) for (const [p, r] of Object.entries(result)) {
  console.log(`== ${p} ${r.total}`);
  for (const [f, c] of Object.entries(r.files).sort((a, b) => b[1] - a[1]).slice(0, args.includes("--all") ? 1e9 : 12)) console.log(`  ${String(c).padStart(4)}  ${f}`);
}
const baseline = existsSync(baselinePath) ? JSON.parse(readFileSync(baselinePath, "utf8")) : null;
let failed = false;
for (const [p, r] of Object.entries(result)) {
  const b = baseline?.[p];
  const status = b == null ? "(no baseline)" : r.total > b ? `✗ up from ${b}` : r.total < b ? `↓ from ${b} — run --baseline to lock it in` : "= baseline";
  if (b != null && r.total > b) failed = true;
  console.log(`${p.padEnd(8)} ${String(r.total).padStart(5)} literals equal to a token value ${status}`);
}
if (failed) { console.error("\n✗ hard-coded visual values increased — reference the token (FlareSizes / FlareColors / var(--flare-*)) instead of repeating its value."); process.exit(1); }
