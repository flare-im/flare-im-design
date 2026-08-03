#!/usr/bin/env node
/**
 * 从 components.json 生成 README 的组件目录段落。
 *
 * 为什么要自动生成：这份目录曾经手写，写着「18 个 / 5 类」，而实际契约里已经是
 * 107 个 / 11 类 —— 漏掉了 Form / Contacts / Moments / Profile / Call / Layout
 * 六个类目整体。README 是这个包在 npm 上的门面，把库的规模少说了 6 倍。
 *
 * 手写目录必然随契约增长而腐烂，所以改成生成。
 *
 * 用法：
 *   node gen-readme-catalog.mjs          # 写回 README.md
 *   node gen-readme-catalog.mjs --check  # 只校验是否最新（CI 用，不一致则退出码 1）
 */
import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = dirname(fileURLToPath(import.meta.url));
const START = "<!-- CATALOG:START -->";
const END = "<!-- CATALOG:END -->";

const spec = JSON.parse(readFileSync(join(ROOT, "components.json"), "utf8"));
const labels = spec.categoryLabels ?? {};

const byCategory = new Map();
for (const c of spec.components) {
  const key = c.category ?? "Uncategorized";
  if (!byCategory.has(key)) byCategory.set(key, []);
  byCategory.get(key).push(c.name);
}

// 类目按组件数降序，同数按名字排，输出稳定 —— 否则每次生成都产生无意义 diff
const ordered = [...byCategory.entries()].sort(
  (a, b) => b[1].length - a[1].length || a[0].localeCompare(b[0]),
);

const total = spec.components.length;
const lines = [
  START,
  `## 组件目录`,
  ``,
  `**${total} 个组件 / ${ordered.length} 个类目**（源见 [\`components.json\`](./components.json)；`,
  `props/events 从 \`@flare-im/vue-ui\` 源码抽取校准）。`,
  ``,
  `> 本段由 \`gen-readme-catalog.mjs\` 从契约生成，不要手改 —— 手写目录会随契约增长而腐烂。`,
  ``,
];

for (const [cat, names] of ordered) {
  // categoryLabels 的值是 { en, zh } 对象，取中文；缺失时退回类目名本身
  const zh = labels[cat]?.zh;
  const label = zh && zh !== cat ? `${cat}（${zh}）` : cat;
  lines.push(`- **${label}** — ${names.length} 个`);
  lines.push(`  ${names.sort().map((n) => `\`${n}\``).join(" · ")}`);
}

lines.push("", END);
const block = lines.join("\n");

const readmePath = join(ROOT, "README.md");
const readme = readFileSync(readmePath, "utf8");

const s = readme.indexOf(START);
const e = readme.indexOf(END);
if (s < 0 || e < 0) {
  console.error(`README.md 里找不到 ${START} / ${END} 标记，无法定位插入点。`);
  process.exit(2);
}
const next = readme.slice(0, s) + block + readme.slice(e + END.length);

if (process.argv.includes("--check")) {
  if (next !== readme) {
    console.error("README 的组件目录已过期，请运行：node spec/gen-readme-catalog.mjs");
    process.exit(1);
  }
  console.log(`✅ 组件目录是最新的（${total} 个 / ${ordered.length} 类）`);
} else {
  writeFileSync(readmePath, next);
  console.log(`README 组件目录已更新：${total} 个组件 / ${ordered.length} 个类目`);
}
