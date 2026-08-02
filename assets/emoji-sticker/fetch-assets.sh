#!/usr/bin/env bash
# 拉取表情/贴纸二进制资源（webp）。
#
# 为什么资源不在版本控制里：
#   250 个动画 webp 共 67 MB。它们曾经提交在 git 里（而且因为 SwiftPM 不跟随
#   符号链接，iOS 还额外存了一份镜像 —— 合计 134 MB）。实测后果是完整
#   `git clone` 连续失败（Connection reset by peer / early EOF），而 iOS SPM
#   只能完整克隆，于是「为了让 iOS 能用」的这份资源反而让 iOS 装不上。
#   清出历史后仓库从 80 MB 降到 2.0 MB。
#
# 元数据（manifest.json / emoji-locales.json）仍在版本控制里 —— 它们是文本，
# 是跨端契约的一部分，必须随代码一起演进。只有二进制走这里。
#
# 用法：
#   ./fetch-assets.sh              # 表情 + 贴纸都拉
#   ./fetch-assets.sh emoji        # 只拉表情（22 MB）
#   ./fetch-assets.sh stickers     # 只拉贴纸（45 MB）
set -euo pipefail

REPO="flare-im/flare-im-design"
TAG="${FLARE_ASSETS_TAG:-assets-v1}"
here="$(cd "$(dirname "$0")" && pwd)"

want="${1:-all}"

fetch() {
  local name="$1" dir="$2"
  if [ -d "$here/$dir" ] && [ -n "$(find "$here/$dir" -name '*.webp' -print -quit 2>/dev/null)" ]; then
    echo "✓ $name 已存在，跳过（要强制重拉先删掉 $dir/）"
    return
  fi
  echo "→ 拉取 $name …"
  gh release download "$TAG" --repo "$REPO" --pattern "$name-assets.tar.gz" \
     --output "$here/.$name.tar.gz" --clobber
  tar -xzf "$here/.$name.tar.gz" -C "$here"
  rm -f "$here/.$name.tar.gz"
  echo "✓ $name: $(find "$here/$dir" -name '*.webp' | wc -l | tr -d ' ') 个 webp"
}

case "$want" in
  emoji)    fetch emoji emoji ;;
  stickers) fetch sticker stickers ;;
  all)      fetch emoji emoji; fetch sticker stickers ;;
  *) echo "用法: $0 [all|emoji|stickers]" >&2; exit 2 ;;
esac

cat <<'NOTE'

下一步：
  - iOS 还需要把资源镜像进 SwiftPM 包（它不跟随符号链接）：
      ../../ios-im-ui/sync-resources.sh
    不跑这步 swift build 会失败，报错是 "type 'Bundle' has no member 'module'"。
  - Vue / Flutter / Android 走符号链接指向本目录，无需额外操作。
NOTE
