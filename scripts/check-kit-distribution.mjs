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

const android = androidVersion();
const npm = npmVersion();
const tag = latestTag();

console.log("kit 版本号三处对照：");
console.log(`  android-im-ui   ${android ?? "—"}`);
console.log(`  vue-im-ui(npm)  ${npm ?? "—"}`);
console.log(`  git tag(iOS)    ${tag ?? "—"}`);

if (android && npm && android !== npm) {
  problems.push(
    `Android(${android}) 与 npm(${npm}) 版本不一致。` +
      "同一版本号在两端会拿到不同组件。"
  );
}
if (android && tag && android !== tag) {
  problems.push(
    `Android(${android}) 与 git tag(${tag}) 不一致。\n` +
      "    iOS 的 SPM 版本**只**来自 git tag：tag 落后就是静默拿旧代码，\n" +
      "    表现为「Android 和 iOS 的 UI 不一样」，而没人会怀疑到版本号。\n" +
      `    补 tag：git tag ${android} && git push origin ${android}`
  );
}

// ---------- 结论 ----------

if (problems.length) {
  console.error("\n✗ kit 分发一致性检查失败：\n");
  for (const p of problems) console.error(`  - ${p}\n`);
  process.exit(1);
}

console.log("\n✓ SPM 双清单同步、三处版本号一致");
