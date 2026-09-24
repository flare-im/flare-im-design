#!/usr/bin/env node
/**
 * 跨端视觉契约门禁 —— 同一个槽位在四端必须解析到同一个 token。
 *
 * 为什么需要它:仓里已有的 `spec/signature-report.mjs` 比的是四端的 **props / events
 * 签名**,`tooling/check-component-contracts.mjs` 比的是组件**是否存在**。两者都通过,
 * 四端依然可以长得完全不一样 —— 因为没有任何一条门禁看的是**解析出来的数值**。
 *
 * 实测过的例子(本门禁建立时四端的真实状态):
 *   气泡圆角  iOS 16/4  Android 16/4  Flutter 16/4  Vue 14/10 + 另一套 13/6
 *   气泡内距  三端 14/9                              Vue 11/8
 *   会话行横内距 三端 spacingSm(8)                    Vue 10px
 *   页头      三端 bgPrimary+实色分隔线               Vue bgSecondary+72% 稀释
 *
 * 判据是「引用了同一个 token」而不是「数值相等」:数值相等可能只是今天碰巧,
 * 引用同一个 token 才是结构上不会再分叉。
 */
import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const spec = JSON.parse(readFileSync(join(root, "spec/cross-platform-visual-contract.json"), "utf8"));

const failures = [];
let checked = 0;

for (const slot of spec.slots) {
  for (const [platform, rule] of Object.entries(slot.platforms)) {
    let source;
    try {
      source = readFileSync(join(root, rule.file), "utf8");
    } catch {
      failures.push(`${slot.id} · ${platform}: 读不到 ${rule.file}`);
      continue;
    }
    for (const pattern of rule.require ?? []) {
      checked += 1;
      if (!new RegExp(pattern).test(source)) {
        failures.push(`${slot.id} · ${platform}: 缺少 ${pattern} → ${rule.file}`);
      }
    }
    for (const pattern of rule.forbid ?? []) {
      checked += 1;
      if (new RegExp(pattern).test(source)) {
        failures.push(`${slot.id} · ${platform}: 出现了应当被 token 取代的裸值 ${pattern} → ${rule.file}`);
      }
    }
  }
}

if (failures.length) {
  console.error("跨端视觉契约 FAIL —— 某个槽位在某一端脱离了共同的 token:");
  for (const f of failures) console.error("  " + f);
  console.error(`\n（真源在 tokens/tokens.json;改完跑 node tokens/build.mjs 重新生成四端。）`);
  process.exit(1);
}
console.log(`跨端视觉契约 PASS: ${spec.slots.length} 个槽位 × 四端,${checked} 条断言`);
