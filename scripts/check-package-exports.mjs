#!/usr/bin/env node
/**
 * 对着**打包产物**验 exports 映射：消费方实际 import 的每个子路径都必须能解析到
 * 包里真实存在的文件。
 *
 *   node scripts/check-package-exports.mjs
 *
 * # 为什么需要它，以及为什么它必须验 tarball 而不是工作目录
 *
 * 这个包发布的是 `.ts`/`.vue` **源码**，消费方靠 exports 映射进包。工作区里所有
 * 消费方还额外有 vite alias 与 tsconfig paths 指向同级仓源码 —— 于是 exports 映射
 * 写错、写漏、或漏了 `files` 里的文件，**在本工作区一律无感**，只有真装 npm 包才炸。
 *
 * 已经这样炸过两次：
 *
 * - 发布包缺表情元数据（`files` 没带上，alias 掩盖）
 * - exports 只枚举了几个 barrel，而消费方实际深挖 40 个子路径；补通配后仍不够，
 *   因为 **exports 不做扩展名猜测**：`./composables/useViewport` 这类无扩展名的
 *   深挖，只有把目标写成回退数组 `[./src/*, ./src/*.ts, ./src/*.vue]` 才解析得到。
 *
 * 完整的判据是「真装包再构建」（工作区根的 `scripts/verify-published-kit.mjs`），
 * 但那需要同级的消费方仓，而它们不是公开仓 —— **CI 里跑不了**。本脚本是那件事里
 * 能自包含、能进 CI 的部分：不装任何依赖、不编译，只做解析。
 *
 * # 解析规则（与 bundler / TS 的行为一致）
 *
 * 显式条目优先于通配；通配之间静态前缀更长者优先；目标是数组时**依次尝试、
 * 取第一个真实存在的文件**。刻意不用 Node 的 `import.meta.resolve`：它对
 * 数组回退与文件存在性的处理会让不存在的目标也「解析成功」，那就成了假绿。
 */

import { execFileSync } from "node:child_process";
import { existsSync, mkdtempSync, readFileSync, readdirSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const packageDir = join(dirname(fileURLToPath(import.meta.url)), "..", "vue-im-ui");

/**
 * 消费方实际 import 的子路径。
 *
 * 来源：2026-08-18 对 flare-im-core-client-sdk/examples 与
 * flare-social/flare-social-sdk/examples/apps 全量扫描 `from "@flare-im/vue-ui…"`
 * 得到的 49 条。**别手工精简**：`./shared/config/messageMenu`、
 * `./composables/useViewport` 这些看着"内部"的路径正是真实用法，也正是
 * 扩展名回退那个坑的触发点。
 *
 * 消费方仓不是公开仓，CI 无法扫活的列表，所以这里是快照。活列表由工作区根的
 * verify-published-kit.mjs 在真构建时覆盖。
 */
const CONSUMER_SUBPATHS = [
  ".",
  "./app",
  "./components",
  "./components/composer/EnhancedComposer.vue",
  "./components/conversation/FlareAvatar.vue",
  "./components/conversation/FlareConversationRow.vue",
  "./components/general/FlareEmptyState.vue",
  "./components/general/FlareSearchBar.vue",
  "./components/general/FlareSearchResults.vue",
  "./components/messages/MessageList.vue",
  "./components/messages/MessageStatus.vue",
  "./components/messages/MessagesView/views/AudioView.vue",
  "./components/messages/MessagesView/views/CardView.vue",
  "./components/messages/MessagesView/views/EmojiView.vue",
  "./components/messages/MessagesView/views/FileView.vue",
  "./components/messages/MessagesView/views/ForwardView.vue",
  "./components/messages/MessagesView/views/ImageGroupView.vue",
  "./components/messages/MessagesView/views/ImageView.vue",
  "./components/messages/MessagesView/views/InfoCardView.vue",
  "./components/messages/MessagesView/views/LinkCardView.vue",
  "./components/messages/MessagesView/views/LocationView.vue",
  "./components/messages/MessagesView/views/NotificationView.vue",
  "./components/messages/MessagesView/views/PlaceholderView.vue",
  "./components/messages/MessagesView/views/QuoteView.vue",
  "./components/messages/MessagesView/views/RichTextView.vue",
  "./components/messages/MessagesView/views/StickerView.vue",
  "./components/messages/MessagesView/views/SystemView.vue",
  "./components/messages/MessagesView/views/TextView.vue",
  "./components/messages/MessagesView/views/VideoView.vue",
  "./components/messages/business/FlareAnnouncementMessageView.vue",
  "./components/messages/business/FlareMiniProgramMessageView.vue",
  "./components/messages/business/FlareScheduleMessageView.vue",
  "./components/messages/business/FlareTaskMessageView.vue",
  "./components/messages/business/FlareVoteMessageView.vue",
  "./composables",
  "./composables/sdk",
  "./composables/useMediaResolver",
  "./composables/useNotificationRenderer",
  "./composables/useViewport",
  "./contracts",
  "./icon-glyphs",
  "./shared/config/messageMenu",
  "./shared/contracts/conversation",
  "./shared/contracts/messageRow",
  "./shared/contracts/search",
  "./theme",
  "./utils",
  "./utils/contentElem",
  "./shared/i18n/useFlareI18n",
];

/** 显式条目优先；通配之间静态前缀长者优先。 */
function matchTargets(exportsMap, subpath) {
  if (Object.hasOwn(exportsMap, subpath)) return { pattern: subpath, targets: exportsMap[subpath], star: null };

  let best = null;
  for (const [pattern, targets] of Object.entries(exportsMap)) {
    const starIndex = pattern.indexOf("*");
    if (starIndex < 0) continue;
    const prefix = pattern.slice(0, starIndex);
    const suffix = pattern.slice(starIndex + 1);
    if (!subpath.startsWith(prefix) || !subpath.endsWith(suffix)) continue;
    if (subpath.length < prefix.length + suffix.length) continue;
    if (best && prefix.length <= best.prefix.length) continue;
    best = { pattern, targets, prefix, star: subpath.slice(prefix.length, subpath.length - suffix.length) };
  }
  return best;
}

function resolveInPackage(root, exportsMap, subpath) {
  const match = matchTargets(exportsMap, subpath);
  if (!match) return { ok: false, reason: "exports 里没有任何条目匹配" };

  const targets = Array.isArray(match.targets) ? match.targets : [match.targets];
  const tried = [];
  for (const target of targets) {
    if (typeof target !== "string") continue;
    const filled = match.star === null ? target : target.replaceAll("*", match.star);
    tried.push(filled);
    if (existsSync(join(root, filled))) return { ok: true, resolved: filled, pattern: match.pattern };
  }
  return { ok: false, reason: `匹配 "${match.pattern}"，但目标都不存在：${tried.join(" | ")}` };
}

const stage = mkdtempSync(join(tmpdir(), "flare-kit-exports-"));
let failures = 0;

try {
  execFileSync("npm", ["pack", "--pack-destination", stage], { cwd: packageDir, stdio: ["ignore", "pipe", "pipe"] });
  const tarball = readdirSync(stage).find((f) => f.endsWith(".tgz"));
  execFileSync("tar", ["-xzf", join(stage, tarball)], { cwd: stage });
  const root = join(stage, "package");

  const manifest = JSON.parse(readFileSync(join(root, "package.json"), "utf8"));
  const exportsMap = manifest.exports;
  if (!exportsMap || typeof exportsMap !== "object") {
    console.error("✗ 打包产物的 package.json 没有 exports 映射。");
    process.exit(1);
  }

  console.log(`对着 ${tarball} 验 ${CONSUMER_SUBPATHS.length} 个消费方子路径\n`);

  // 显式条目也一并验：条目指向的文件被 `files` 漏掉过一次（表情元数据）。
  const explicit = Object.keys(exportsMap).filter((k) => !k.includes("*"));
  const all = [...new Set([...explicit, ...CONSUMER_SUBPATHS])];

  for (const subpath of all.sort()) {
    const result = resolveInPackage(root, exportsMap, subpath);
    if (!result.ok) {
      failures += 1;
      console.log(`  ✗ ${subpath}\n      ${result.reason}`);
    }
  }

  if (!failures) console.log(`  ✓ 全部 ${all.length} 个子路径都解析到了包内真实存在的文件`);
} finally {
  rmSync(stage, { recursive: true, force: true });
}

if (failures) {
  console.log(`\n✗ ${failures} 个子路径解析失败。`);
  console.log("  别靠在消费方加 alias / paths 绕过——那恰好是让这类缺陷隐身的东西。");
  console.log("  要么给 exports 补条目（无扩展名的深挖需要回退数组），要么确认 files 带上了该文件。");
  process.exit(1);
}
