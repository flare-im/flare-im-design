#!/usr/bin/env node
// Validates the L2 component contract: completeness + that the reference
// symbols actually exist in the realised packages (anti-drift, like sdk-spec's
// two-way coverage). Vue = flare-im-design/vue-im-ui; Flutter = flutter-im-ui.
// Run: node validate.mjs
import { readFileSync, existsSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import { execSync } from "node:child_process";
import { PLATFORMS, vueExportMap, loadSurface, compareComponent } from "./signatures.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const spec = JSON.parse(readFileSync(join(here, "components.json"), "utf8"));
const vueRoot = join(here, "../vue-im-ui/src");
const flutterRoot = join(here, "../flutter-im-ui/lib");
const iosRoot = join(here, "../ios-im-ui/Sources");
const composeRoot = join(here, "../android-im-ui/src/main");

const errors = [];
const coverage = {}; // platform -> 未实现的组件名列表
const platforms = ["vue", "flutter", "ios", "compose"];
const vueExports = vueExportMap(vueRoot);
const signatureRoots = { vueExports, flutter: flutterRoot, ios: iosRoot, compose: composeRoot };

// ── Vue 事件面提取 ────────────────────────────────────────────────────────
// 契约里的 events 曾经声明过实现里根本不存在的事件（MessageActionSheet 声明
// 10 个、实际只有一个 build(op)；ConversationList 声明 3 个、实际是纯插槽容器
// 一个都没有）。照契约接线的人不会报错，只会静默收不到回调 —— 比红着的校验器
// 危险得多。所以把「声明的事件必须在 Vue 参考实现里找得到」做成门禁。
// 事件名在模板里可以是 kebab-case（toggle-panel ↔ togglePanel），两种都算同一个。
const normEvent = (n) => String(n).replace(/-([a-zA-Z])/g, (_, c) => c.toUpperCase());

/** 返回一个 .vue 文件真实声明的事件名集合（未归一化）。 */
function vueEmitSurface(src) {
  const names = new Set();
  // defineModel() 等价于声明 update:modelValue；具名 model 声明 update:<name>。
  for (const m of src.matchAll(/defineModel\s*(?:<[^<>]*>)?\s*\(\s*(?:["'`]([^"'`]+)["'`])?/g))
    names.add(m[1] ? `update:${m[1]}` : "update:modelValue");
  let i = 0;
  while ((i = src.indexOf("defineEmits", i)) !== -1) {
    i += "defineEmits".length;
    while (i < src.length && /\s/.test(src[i])) i++;
    let block = "";
    if (src[i] === "<") {
      // 类型字面量形式，可能横跨多行；注意 `) => void` 里的 ">" 不是闭合括号。
      let depth = 0;
      for (let j = i; j < src.length; j++) {
        if (src[j] === "<") depth++;
        else if (src[j] === ">") {
          if (src[j - 1] === "=") continue;
          if (--depth === 0) { block = src.slice(i + 1, j); i = j; break; }
        }
      }
    } else if (src[i] === "(") {
      // 运行时形式：defineEmits(["a", "b"]) / defineEmits({ a: null })
      let depth = 0;
      for (let j = i; j < src.length; j++) {
        if (src[j] === "(") depth++;
        else if (src[j] === ")") { if (--depth === 0) { block = src.slice(i + 1, j); i = j; break; } }
      }
    }
    if (!block) continue;
    // 调用签名写法：(e: "x", …): void —— 形参名不一定叫 e。
    for (const m of block.matchAll(/\(\s*[A-Za-z_$][\w$]*\s*:\s*["'`]([^"'`]+)["'`]/g)) names.add(m[1]);
    // 具名元组写法：x: [payload] / "x": [payload]
    for (const m of block.matchAll(
      /(?:^|[;,{\n])\s*(?:["'`]([^"'`]+)["'`]|([A-Za-z_$][\w$-]*))\s*:\s*\[/g,
    )) names.add(m[1] ?? m[2]);
    // 数组字面量写法：["a", "b"]
    if (/^\s*\[/.test(block)) for (const m of block.matchAll(/["'`]([^"'`]+)["'`]/g)) names.add(m[1]);
  }
  return names;
}

for (const c of spec.components) {
  const where = `component "${c.name}"`;
  // "planned" components are contract-only: their four-platform symbols need not
  // exist yet (they're being built out). Contract completeness is still enforced.
  const planned = c.status === "planned";
  if (!c.category) errors.push(`${where}: missing category`);
  // summary/dataSource are bilingual objects — both languages required
  for (const f of ["summary", "dataSource"]) {
    const v = c[f];
    if (!v || typeof v !== "object" || !v.en || !v.zh)
      errors.push(`${where}: ${f} must be bilingual { en, zh }`);
  }
  if (c.notes !== undefined && (!c.notes?.en || !c.notes?.zh))
    errors.push(`${where}: notes must be bilingual { en, zh }`);
  // props required non-empty; states/events optional (display-only components have none)
  if (!Array.isArray(c.props) || c.props.length === 0) errors.push(`${where}: empty props`);
  for (const f of ["states", "events"])
    if (c[f] !== undefined && !Array.isArray(c[f])) errors.push(`${where}: ${f} must be an array`);
  // 平台覆盖分两类，性质完全不同，不能混为一谈：
  //   ① 声明了但字段残缺 → **契约撒谎**，是错误
  //   ② 整个平台缺失     → 该端尚未实现，是已知状态，计入覆盖率而非报错
  // 混在一起会让校验器长期红着，红久了就没人看了 —— 那才是真正的失效。
  for (const p of platforms) {
    const b = c.platforms?.[p];
    if (b === undefined) {
      (coverage[p] ??= []).push(c.name); // 未实现，稍后汇总
    } else if (!b.package || !b.symbol) {
      errors.push(`${where}: platform ${p} 声明了却缺 package/symbol（契约不完整）`);
    }
  }
  for (const pr of c.props ?? []) {
    if (!pr.name || !pr.type) errors.push(`${where}: prop missing name/type: ${JSON.stringify(pr)}`);
    else if (!pr.description?.en || !pr.description?.zh)
      errors.push(`${where}: prop "${pr.name}" missing bilingual description { en, zh }`);
    if (pr.name && !/^[a-z][A-Za-z0-9]*$/.test(pr.name))
      errors.push(`${where}: prop "${pr.name}" must be camelCase (v-model belongs in the "model" field)`);
    if (pr.platforms && pr.platforms.some((p) => !platforms.includes(p)))
      errors.push(`${where}: prop "${pr.name}" has unknown platforms ${JSON.stringify(pr.platforms)}`);
  }
  // 事件名：契约层统一 camelCase（Vue 模板按 kebab 派生、原生按 on+Pascal 派生）
  for (const e of c.events ?? []) {
    if (!/^(update:)?[a-z][A-Za-z0-9]*$/.test(String(e)))
      errors.push(`${where}: event "${e}" must be camelCase in the contract (implementations derive kebab / onXxx)`);
  }
  if (c.model && (!c.model.prop || !c.model.event))
    errors.push(`${where}: model must be { prop, event }`);

  // anti-drift: the Vue reference symbol must exist as a component file
  // 契约的 vue symbol 必须是 components/index.ts 的导出名——宿主照文档 import 的就是它，
  // 写成文件名（MessageBubble）而不是导出名（FlareMessageBubble）会直接编译失败。
  const sym = c.platforms?.vue?.symbol;
  if (sym && !planned) {
    const files = vueExports[sym] && existsSync(vueExports[sym]) ? [vueExports[sym]] : [];
    if (!files.length) errors.push(`${where}: Vue symbol ${sym} is not exported from vue-im-ui/src/components/index.ts`);
    else {
      // 事件与 props 的实现一致性由下方「四端签名」段统一校验（含平台范围与别名）。
    }
  }

  // anti-drift: the Flutter symbol must exist as a Dart class in flutter-im-ui
  const fsym = c.platforms?.flutter?.symbol;
  if (fsym && !planned) {
    let found = false;
    try {
      const out = execSync(
        `grep -rlE "class ${fsym}\\b" "${flutterRoot}" --include=*.dart`,
        { encoding: "utf8" },
      );
      found = out.trim().length > 0;
    } catch { /* grep found nothing → non-zero exit */ }
    if (!found) errors.push(`${where}: Flutter symbol class ${fsym} not found in flutter-im-ui`);
  }

  // anti-drift: the iOS symbol must exist as a SwiftUI struct in ios-im-ui
  const isym = c.platforms?.ios?.symbol;
  if (isym && !planned) {
    let found = false;
    try {
      const out = execSync(
        `grep -rlE "(struct|enum) ${isym}\\b" "${iosRoot}" --include=*.swift`,
        { encoding: "utf8" },
      );
      found = out.trim().length > 0;
    } catch { /* none */ }
    if (!found) errors.push(`${where}: iOS symbol ${isym} not found in ios-im-ui`);
  }

  // anti-drift: the Compose symbol must exist as a @Composable fun in compose-im-ui
  const csym = c.platforms?.compose?.symbol;
  if (csym && !planned) {
    let found = false;
    try {
      const out = execSync(
        `grep -rlE "fun ${csym}\\b" "${composeRoot}" --include=*.kt`,
        { encoding: "utf8" },
      );
      found = out.trim().length > 0;
    } catch { /* none */ }
    if (!found) errors.push(`${where}: Compose symbol fun ${csym} not found in compose-im-ui`);
  }
}

// ── 四端签名 vs 契约（棘轮）──────────────────────────────────────────────
// 每个组件每个端：契约声明的 props/事件必须能在实现签名里找到（允许 lexicon /
// eventAliases / platformAliases 登记的平台惯用名），实现里的 onXxx 回调也必须在
// 契约里。历史差异记在 signature-baseline.json；这里只允许差异集合缩小：
//   · 出现基线里没有的差异 → 错（契约或实现漂移了）
//   · 基线里的差异已经消失 → 也错，提示重生成基线（否则基线自己会腐烂）
{
  const baselinePath = join(here, "signature-baseline.json");
  const baseline = existsSync(baselinePath) ? JSON.parse(readFileSync(baselinePath, "utf8")) : {};
  const current = {};
  for (const c of spec.components) {
    if (c.status === "planned") continue;
    for (const p of PLATFORMS) {
      if (!c.platforms?.[p]) continue;
      const surface = loadSurface(signatureRoots, c, p);
      if (!surface) continue; // 符号缺失已在上面报错
      const d = compareComponent(spec, c, p, surface);
      const items = [
        ...d.missingProps.map((x) => `prop "${x}" declared but not implemented`),
        ...d.missingEvents.map((x) => `event "${x}" declared but not implemented`),
        ...d.extraEvents.map((x) => `callback "${x}" implemented but not in the contract`),
      ];
      if (items.length) (current[c.name] ??= {})[p] = { missingProps: d.missingProps, missingEvents: d.missingEvents, extraEvents: d.extraEvents };
      const base = baseline[c.name]?.[p] ?? { missingProps: [], missingEvents: [], extraEvents: [] };
      for (const x of d.missingProps) if (!base.missingProps?.includes(x)) errors.push(`component "${c.name}" [${p}]: prop "${x}" is declared in the contract but the ${c.platforms[p].symbol} signature has no such parameter (add it, scope the prop with "platforms", or register an alias)`);
      for (const x of d.missingEvents) if (!base.missingEvents?.includes(x)) errors.push(`component "${c.name}" [${p}]: event "${x}" is declared in the contract but ${c.platforms[p].symbol} has no matching callback`);
      for (const x of d.extraEvents) if (!base.extraEvents?.includes(x)) errors.push(`component "${c.name}" [${p}]: ${c.platforms[p].symbol} exposes callback "${x}" that the contract does not declare`);
      // 基线腐烂检测
      for (const k of ["missingProps", "missingEvents", "extraEvents"])
        for (const x of base[k] ?? []) if (!d[k].includes(x)) errors.push(`signature-baseline.json is stale: "${c.name}" [${p}] ${k} "${x}" no longer differs — run \`node spec/signature-report.mjs --baseline\` to shrink the baseline`);
    }
  }
  for (const name of Object.keys(baseline)) {
    if (name.startsWith("_")) continue;
    if (!spec.components.some((c) => c.name === name)) errors.push(`signature-baseline.json lists unknown component "${name}"`);
  }
}

// Hand-written component/category counts in the docs drift the moment the spec
// grows. The site claims the spec is the single source of truth — hold it to that.
{
  const total = spec.components.length;
  const cats = new Set(spec.components.map((c) => c.category)).size;
  const docs = [
    ["site/index.md", `${total} 个组件 · ${cats} 大类`],
    ["site/guide/getting-started.md", `全部 ${total} 个组件`],
    ["site/en/index.md", `${total} components · ${cats} categories`],
    ["site/en/guide/getting-started.md", `all ${total} components`],
  ];
  for (const [rel, expected] of docs) {
    const p = join(here, "..", rel);
    if (!existsSync(p)) continue;
    const text = readFileSync(p, "utf8");
    if (!text.includes(expected)) {
      errors.push(
        `${rel}: stale count — expected to find "${expected}" (spec has ${total} components / ${cats} categories)`,
      );
    }
  }
}

// The iOS package cannot follow the symlink the other platforms use, so it carries
// a mirror of assets/emoji-sticker. Only the text contracts of that mirror are
// tracked (webp stays out of git) — and they must be tracked: without them a clean
// checkout has no Resources/emoji-sticker, SwiftPM emits no Bundle.module and the
// whole package fails to compile. Hold the mirror byte-identical to the source so
// a manifest edit cannot land on one side only.
{
  const src = join(here, "../assets/emoji-sticker");
  const mirror = join(here, "../ios-im-ui/Sources/FlareIMUI/Resources/emoji-sticker");
  for (const rel of ["manifest.json", "emoji-locales.json", "stickers/classic/manifest.json"]) {
    const a = join(src, rel);
    const b = join(mirror, rel);
    if (!existsSync(b)) {
      errors.push(`ios-im-ui resource mirror missing ${rel} — run ios-im-ui/sync-resources.sh and commit it`);
      continue;
    }
    if (readFileSync(a, "utf8") !== readFileSync(b, "utf8")) {
      errors.push(`ios-im-ui resource mirror ${rel} differs from assets/emoji-sticker — run ios-im-ui/sync-resources.sh`);
    }
  }
}

if (errors.length) {
  console.error(`✗ spec invalid (${errors.length}):`);
  for (const e of errors) console.error("  - " + e);
  process.exit(1);
}
const byCat = {};
for (const c of spec.components) (byCat[c.category] ??= []).push(c);
const stableCount = spec.components.filter((c) => c.status !== "planned").length;
const plannedCount = spec.components.length - stableCount;
console.log(
  `✓ spec valid — ${spec.components.length} components in ${Object.keys(byCat).length} categories (${stableCount} stable · 4-platform symbols verified, ${plannedCount} planned · contract-only):\n`,
);
for (const [cat, list] of Object.entries(byCat)) {
  console.log(`  ${cat}`);
  for (const c of list)
    console.log(
      `    · ${c.name.padEnd(22)} ${String(c.props.length).padStart(2)}p ${String((c.states ?? []).length)}s ${String((c.events ?? []).length)}e  ${c.status === "planned" ? "⋯ planned" : "← " + (c.platforms?.compose?.symbol ?? "vue-only")}`,
    );
}

// ── 平台覆盖率 ────────────────────────────────────────────────────────────
// 「某端尚未实现」是已知状态而非错误，所以作为度量呈现。
// 把它和真错误混在一起会让校验器长期红着，红久了就没人看了。
const total = spec.components.length;
console.log("\n平台覆盖率：");
for (const p of ["vue", "flutter", "ios", "compose"]) {
  const missing = coverage[p] ?? [];
  const done = total - missing.length;
  const pct = ((done / total) * 100).toFixed(1);
  console.log(`  ${p.padEnd(8)} ${String(done).padStart(3)}/${total}  ${pct.padStart(5)}%`);
  if (missing.length && missing.length <= 8) console.log(`           未实现：${missing.join(" · ")}`);
  else if (missing.length) console.log(`           未实现 ${missing.length} 个（前 8：${missing.slice(0, 8).join(" · ")} …）`);
}
