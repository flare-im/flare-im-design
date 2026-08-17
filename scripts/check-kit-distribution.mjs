#!/usr/bin/env node
/**
 * kit 分发一致性门禁。
 *
 *   node scripts/check-kit-distribution.mjs
 *
 * 校验两件事，任一失败都退出码 1：
 *
 * ## 1. SPM 双清单必须同步
 *
 * SPM **只认仓库根的 Package.swift**，而这是 monorepo，所以根清单是必需的，
 * 内容与 `ios-im-ui/Package.swift` 重复。
 *
 * 漂移的后果极其隐蔽：
 * - dev 分支走 `.package(path: "…/ios-im-ui")` → 读**子清单** → 正常
 * - main 分支走 `.package(url: …, from: …)` → 读**根清单** → 拿到旧定义
 *
 * 也就是说本地怎么测都是绿的，只有从 git url 拉包的人受影响。
 * 这个坑记忆里记过一次，但「文档里写了要同步」从来挡不住漂移——必须让 CI 报红。
 *
 * ## 2. 三处版本号必须一致
 *
 * 同一个 kit 版本在三个地方各写一遍：
 * - `android-im-ui/build.gradle.kts` 的 `version`
 * - `vue-im-ui/package.json` 的 `version`（npm）
 * - git tag（iOS 的 SPM 版本唯一来源）
 *
 * 任意两处不一致时，**同一个版本号在不同端会拿到不同组件**——
 * 表现是「Android 和 iOS 的 UI 不一样」，而没人会想到是版本号漂移。
 *
 * iOS 尤其危险：它的版本完全靠 git tag，tag 落后就是静默拿旧代码。
 *
 * ### tag 落后要分两种情况，否则这条门禁会长期红
 *
 * 「改版本号」与「发布 + 打 tag」天然有个时间窗口，正常流程里就会出现
 * 「清单是 1.0.9、最新 tag 还是 1.0.8」。把这个窗口也判成失败，等于让 CI
 * 在每次版本 bump 后必红一段时间——而长期红的门禁没人看，就废了。
 *
 * 所以按「该版本是否真的发到 npm 上了」区分：
 *
 * - 已在 npm 上、却没有对应 tag → **失败**。这是真危险状态：别人能装到这个
 *   npm 版本，而 iOS 从 git tag 拿的还是上一版，两端悄悄不一致。
 * - 还没发到 npm → **只提示**。这是发布流程正在进行中的正常中间态。
 *
 * 查不到 registry（离线 / CI 无外网）时退回严格判定，并明说是退回了——
 * 宁可多报一次，也不要因为查不到就静默放过真危险状态。
 */

import { execSync } from "node:child_process";
import { readFileSync, existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const problems = [];

// ---------- 1. SPM 双清单 ----------

function spmFacts(manifestPath) {
  const text = readFileSync(manifestPath, "utf8");
  const pick = (re) => {
    const m = text.match(re);
    return m ? m[1].trim() : null;
  };
  return {
    // 只比对「对外契约」部分：包名、平台下限、产物名。
    // target 的 path 两份必然不同（根清单要带 ios-im-ui/ 前缀），不该比。
    name: pick(/name:\s*"([^"]+)"/),
    platforms: (text.match(/\.(iOS|macOS)\(\.v(\d+)\)/g) || []).sort().join(","),
    products: (text.match(/\.library\(name:\s*"([^"]+)"/g) || []).sort().join(","),
  };
}

const rootManifest = join(root, "Package.swift");
const subManifest = join(root, "ios-im-ui", "Package.swift");

if (!existsSync(rootManifest)) {
  problems.push(
    "缺少仓库根 Package.swift。SPM 只认仓库根清单，没有它则 " +
      "`.package(url: …)` 这条路（main 分支）完全不可用。"
  );
} else if (existsSync(subManifest)) {
  const a = spmFacts(rootManifest);
  const b = spmFacts(subManifest);
  for (const key of ["name", "platforms", "products"]) {
    if (a[key] !== b[key]) {
      problems.push(
        `SPM 双清单的 ${key} 不一致：根清单 ${JSON.stringify(a[key])} ` +
          `vs ios-im-ui ${JSON.stringify(b[key])}。\n` +
          "    dev 走 path 读子清单、main 走 url 读根清单——" +
          "漂移时本地全绿，只有拉 git url 的人拿到旧定义。"
      );
    }
  }
}

// ---------- 2. 三处版本号 ----------

function androidVersion() {
  const f = join(root, "android-im-ui", "build.gradle.kts");
  if (!existsSync(f)) return null;
  const m = readFileSync(f, "utf8").match(/^version\s*=\s*"([^"]+)"/m);
  return m ? m[1] : null;
}

function npmVersion() {
  const f = join(root, "vue-im-ui", "package.json");
  if (!existsSync(f)) return null;
  return JSON.parse(readFileSync(f, "utf8")).version ?? null;
}

function latestTag() {
  try {
    // 只看语义化版本 tag，忽略 dev-backup-* 这类运维 tag。
    const out = execSync("git tag --list", { cwd: root, encoding: "utf8" });
    const versions = out
      .split("\n")
      .map((s) => s.trim())
      .filter((s) => /^\d+\.\d+\.\d+$/.test(s))
      .sort((x, y) => {
        const px = x.split(".").map(Number);
        const py = y.split(".").map(Number);
        for (let i = 0; i < 3; i += 1) if (px[i] !== py[i]) return px[i] - py[i];
        return 0;
      });
    return versions.at(-1) ?? null;
  } catch {
    return null;
  }
}

/**
 * 该版本是否真的发到 registry 上了。
 *
 * 返回 null = 查不到（离线 / 无外网），调用方据此退回严格判定。
 * 注意别用 `npm view <pkg> version`：它只给最新版，回答不了「1.0.9 在不在」
 * 这个问题（回滚或并行分支下最新版可能反而更低）。
 */
function isPublishedOnNpm(version) {
  if (!version) return null;
  try {
    const out = execSync("npm view @flare-im/vue-ui versions --json", {
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
      timeout: 30_000,
    });
    const parsed = JSON.parse(out);
    const all = Array.isArray(parsed) ? parsed : [parsed];
    return all.includes(version);
  } catch {
    return null;
  }
}

const android = androidVersion();
const manifest = npmVersion();
const tag = latestTag();
const published = isPublishedOnNpm(manifest);

console.log("kit 版本号三处对照：");
console.log(`  android-im-ui       ${android ?? "—"}`);
console.log(
  `  vue-im-ui(清单)     ${manifest ?? "—"}` +
    (published === null ? "（registry 查不到，按严格判定）" : published ? "（已发到 npm）" : "（尚未发布）")
);
console.log(`  git tag(iOS)        ${tag ?? "—"}`);

if (android && manifest && android !== manifest) {
  // 这一条没有时间窗口可言：两份清单本来就该同时改。
  problems.push(
    `Android(${android}) 与 npm 清单(${manifest}) 版本不一致。` +
      "同一版本号在两端会拿到不同组件。"
  );
}
if (!tag && published === true) {
  // 一个已发布的版本却读不到任何语义化 tag，只有两种可能：浅克隆（CI 默认
  // fetch-depth: 1 就拿不到 tag），或者 tag 真的没打。两者都必须报出来——
  // 否则这条校验会因为「读不到 tag」而整段跳过，变成「没有 tag 所以没有不一致」
  // 的假绿，而这正是本门禁要防的那类静默失效。
  problems.push(
    `清单版本 ${manifest} 已发到 npm，但仓里读不到任何语义化 git tag。\n` +
      "    要么是浅克隆（CI 里加 fetch-depth: 0），要么是 tag 真的没打。\n" +
      "    iOS 的 SPM 版本只来自 git tag，缺 tag 就是 iOS 拿不到这一版。"
  );
}
if (android && tag && android !== tag) {
  const detail =
    `Android(${android}) 与 git tag(${tag}) 不一致。\n` +
    "    iOS 的 SPM 版本**只**来自 git tag：tag 落后就是静默拿旧代码，\n" +
    "    表现为「Android 和 iOS 的 UI 不一样」，而没人会怀疑到版本号。\n" +
    `    补 tag：git tag ${android} && git push origin ${android}`;

  if (published === false) {
    // 发布流程进行中的正常中间态：清单已 bump，还没 publish/tag。
    console.log(`\n提示：${detail}`);
    console.log("    （该版本还没发到 npm，属发布流程中的正常状态，不判失败）");
  } else {
    problems.push(
      published === null ? `${detail}\n    （registry 查不到，退回严格判定）` : detail
    );
  }
}

// ---------- 结论 ----------

if (problems.length) {
  console.error("\n✗ kit 分发一致性检查失败：\n");
  for (const p of problems) console.error(`  - ${p}\n`);
  process.exit(1);
}

console.log("\n✓ SPM 双清单同步、三处版本号一致");
