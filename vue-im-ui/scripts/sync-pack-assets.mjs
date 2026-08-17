#!/usr/bin/env node
/**
 * 把 kit 需要的表情/贴纸**元数据**从仓库真源同步到包内。
 *
 *   node scripts/sync-pack-assets.mjs          # 同步
 *   node scripts/sync-pack-assets.mjs --check  # 只校验是否已同步（CI 用）
 *
 * # 为什么需要它
 *
 * 真源在 `flare-im-design/assets/emoji-sticker/`（整个目录 67MB，含 250 个 webp）。
 * 代码此前直接 `import "../../../assets/..."` 跨出包目录引用它——
 * **本地开发时因为有 vite alias，这样能跑；装成 npm 包后就跨不出去了**，
 * 表现是 published 模式构建报
 * `Could not resolve "../../../assets/emoji-sticker/emoji-locales.json"`。
 *
 * 这个缺陷被 alias 掩盖了很久：本地永远是绿的，只有真正从 registry 装包才暴露。
 *
 * # 为什么只同步 json，不同步图片
 *
 * 代码只 import 两个元数据 json（合计 20KB）：
 *   - emoji-locales.json           表情短名的多语言映射
 *   - stickers/classic/manifest.json  贴纸包清单
 *
 * 图片（67MB）由消费方按 manifest 自行加载，不该进 npm 包——
 * 记忆里记过一次教训：把 webp 提交进仓库导致 `git clone` 崩掉。
 *
 * # 为什么是同步而不是让代码读真源
 *
 * 包发布出去后没有「真源目录」这个概念，必须自带。而复制会带来漂移风险，
 * 所以配一个 `--check` 模式接进 CI：真源改了但包内没同步时直接报红。
 */

import { readFileSync, writeFileSync, mkdirSync, existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const pkgRoot = join(dirname(fileURLToPath(import.meta.url)), "..");
const sourceRoot = join(pkgRoot, "..", "assets", "emoji-sticker");
const targetRoot = join(pkgRoot, "src", "assets", "emoji-sticker");

/** 代码真正 import 的元数据文件（相对 emoji-sticker 根）。 */
const FILES = ["emoji-locales.json", "stickers/classic/manifest.json"];

const checkOnly = process.argv.includes("--check");
let drifted = 0;

for (const rel of FILES) {
  const from = join(sourceRoot, rel);
  const to = join(targetRoot, rel);

  if (!existsSync(from)) {
    console.error(`✗ 真源缺失：${from}`);
    console.error("  这不是同步问题——assets/emoji-sticker 下少了文件，先查真源。");
    process.exit(1);
  }

  const source = readFileSync(from, "utf8");
  const current = existsSync(to) ? readFileSync(to, "utf8") : null;

  if (source === current) {
    if (!checkOnly) console.log(`  · ${rel}（已同步）`);
    continue;
  }

  drifted += 1;
  if (checkOnly) {
    console.error(`✗ ${rel} 与真源不一致`);
    continue;
  }

  mkdirSync(dirname(to), { recursive: true });
  writeFileSync(to, source);
  console.log(`  ✓ ${rel}`);
}

if (checkOnly) {
  if (drifted) {
    console.error("");
    console.error(`${drifted} 个文件与真源漂移。运行 node scripts/sync-pack-assets.mjs 同步。`);
    console.error("放着不管的后果：npm 包里的表情短名/贴纸清单是旧的，");
    console.error("而本地开发看不出来（本地走 alias 读真源）。");
    process.exit(1);
  }
  console.log("✓ 包内元数据与真源一致");
}
