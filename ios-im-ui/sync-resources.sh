#!/usr/bin/env bash
# Mirrors the cross-platform emoji/sticker source into this SwiftPM package.
#
# 唯一真源是 flare-im-design/assets/emoji-sticker。Vue/Flutter/Android 用符号链接
# 直接引用；SwiftPM 的资源拷贝器**不跟随符号链接**，所以 iOS 包需要一份真实副本。
#
# 副本分两层：
#   - 文本契约（manifest.json / emoji-locales.json / stickers/*/manifest.json）
#     **入版本控制**。它们让 Resources/emoji-sticker 在干净检出里也存在，SwiftPM
#     才会生成 Bundle.module，包才编得过。改了 assets/ 里的契约要重跑本脚本并把
#     镜像一起提交；spec/validate.mjs 会校验两边字节一致。
#   - webp 二进制**不入版本控制**（见仓库 .gitignore）。曾经它是提交进 git 的，
#     导致同一份 67MB 在仓库里存两遍（134MB），完整 clone 连续失败——iOS SPM
#     只能完整克隆，于是这份「为了让 iOS 能用」的镜像反而让 iOS 装不上。
#
# 打 tag 不会带上未跟踪文件，所以「发包前跑脚本」救不了 SPM 消费方的 webp：
# 通过 git URL 引入的包只含文本契约（目录能列、图片为空），要图片必须走本地
# 路径/submodule 引入并在检出里跑 fetch-assets.sh + 本脚本。
#
#   ../assets/emoji-sticker/fetch-assets.sh   # 先拉 webp（只需一次）
#   ./sync-resources.sh
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
src="$here/../assets/emoji-sticker/"
dest="$here/Sources/FlareIMUI/Resources/emoji-sticker/"

rsync -a --delete \
  --exclude 'build-manifest.mjs' \
  --exclude 'fetch-assets.sh' \
  --exclude 'README.md' \
  "$src" "$dest"

echo "synced $(find "$dest" -name '*.webp' | wc -l | tr -d ' ') webp into $dest"
