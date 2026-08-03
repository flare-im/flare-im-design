#!/usr/bin/env node
// Validates the L2 component contract: completeness + that the reference
// symbols actually exist in the realised packages (anti-drift, like sdk-spec's
// two-way coverage). Vue = flare-im-design/vue-im-ui; Flutter = flutter-im-ui.
// Run: node validate.mjs
import { readFileSync, existsSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import { execSync } from "node:child_process";

const here = dirname(fileURLToPath(import.meta.url));
const spec = JSON.parse(readFileSync(join(here, "components.json"), "utf8"));
const vueRoot = join(here, "../vue-im-ui/src");
const flutterRoot = join(here, "../flutter-im-ui/lib");
const iosRoot = join(here, "../ios-im-ui/Sources");
const composeRoot = join(here, "../android-im-ui/src/main");

const errors = [];
const coverage = {}; // platform -> 未实现的组件名列表
const platforms = ["vue", "flutter", "ios", "compose"];

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
  }

  // anti-drift: the Vue reference symbol must exist as a component file
  const sym = c.platforms?.vue?.symbol;
  if (sym && !planned) {
    let found = false;
    try {
      const out = execSync(`find "${vueRoot}" -name "${sym}.vue"`, { encoding: "utf8" });
      found = out.trim().length > 0;
    } catch { /* find failed */ }
    if (!found) errors.push(`${where}: Vue reference symbol ${sym}.vue not found in vue-im-ui`);
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
