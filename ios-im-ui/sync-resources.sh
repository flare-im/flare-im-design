#!/usr/bin/env bash
# Mirrors the cross-platform emoji/sticker source into this SwiftPM package.
#
# The single source of truth is flare-im-design/assets/emoji-sticker. Vue/Flutter/
# Android reference it directly (symlink); SwiftPM's resource copier does NOT follow
# symlinks, so the iOS package keeps a real committed mirror instead. Re-run this
# whenever the central assets change:
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
