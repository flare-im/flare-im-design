#!/usr/bin/env bash
# Mirrors the cross-platform emoji/sticker source into this SwiftPM package.
#
# 唯一真源是 flare-im-design/assets/emoji-sticker。Vue/Flutter/Android 用符号链接
# 直接引用；SwiftPM 的资源拷贝器**不跟随符号链接**，所以 iOS 包需要一份真实副本。
#
# ⚠️ 这份副本**不入版本控制**（见仓库 .gitignore）。曾经它是提交进 git 的，
# 导致同一份 67MB 资源在仓库里存两遍（134MB），完整 clone 连续失败——
# iOS SPM 只能完整克隆，于是这份「为了让 iOS 能用」的镜像反而让 iOS 装不上。
#
# 因此：**每次发 iOS 包（打 tag）之前必须先跑本脚本**，否则发出去的包不含资源。
#
#   ./sync-resources.sh
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
src="$here/../assets/emoji-sticker/"
dest="$here/Sources/FlareIMUI/Resources/emoji-sticker/"

rsync -a --delete \
  --exclude 'build-manifest.mjs' \
  --exclude 'README.md' \
  "$src" "$dest"

echo "synced $(find "$dest" -name '*.webp' | wc -l | tr -d ' ') webp into $dest"
