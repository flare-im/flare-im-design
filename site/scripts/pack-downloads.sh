#!/usr/bin/env bash
# Builds downloadable source archives for the four platform packages into
# site/public/downloads/, so the docs site can serve them via a plain link.
# Re-run after cutting a new version. Does NOT publish anything.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"   # site/
root="$(cd "$here/.." && pwd)"                             # flare-im-design/
out="$here/public/downloads"
mkdir -p "$out"
rm -f "$out"/*.tgz "$out"/*.tar.gz 2>/dev/null || true

echo "→ vue (npm pack)"
( cd "$root/vue-im-ui" && npm pack --silent --pack-destination "$out" >/dev/null )

# tar helper: archive a package dir, excluding build/vcs junk
pack_dir () {
  local dir="$1" name="$2"
  echo "→ $name (tar)"
  tar -C "$root" \
    --exclude='.git' --exclude='build' --exclude='.gradle' \
    --exclude='.dart_tool' --exclude='.build' --exclude='*.iml' \
    --exclude='Pods' --exclude='DerivedData' \
    -czf "$out/$name" "$dir"
}

pack_dir "flutter-im-ui" "flare_im_ui-flutter-0.1.0.tar.gz"
pack_dir "ios-im-ui"     "FlareIMUI-ios-0.1.0.tar.gz"
pack_dir "android-im-ui" "flare-im-ui-compose-android-0.1.0.tar.gz"

echo ""
echo "Archives in $out:"
( cd "$out" && ls -1sh *.tgz *.tar.gz )
