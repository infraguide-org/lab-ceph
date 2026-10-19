#!/usr/bin/env bash
# Source: https://github.com/infraguide-org/lab-ceph
# Copyright (c) 2026 infraguide.org, MIT License
#
# Builds the decks in the requested formats into the output directory of .marprc.yml
# and copies assets/ next to them, so the pictures also load in the built html.
# Usage: build.sh [src-dir] [format...]   (default: src-dir = slides/src, html only)
# Set MARP to pick the Marp CLI command, e.g. MARP="npx --yes @marp-team/marp-cli@4".
set -euo pipefail

src=$(realpath "${1:-$(dirname "$(realpath "$0")")/../src}")
shift || true
formats=("$@")
[ ${#formats[@]} -eq 0 ] && formats=(html)   # pdf and pptx are slow, so ask for them

if [ -z "${MARP:-}" ]; then
  MARP=$(command -v marp >/dev/null && echo marp || echo "npx --yes @marp-team/marp-cli@4")
fi

cd "$src"
out=$(realpath -m "$(sed -n 's/^output: *//p' .marprc.yml | head -1 | sed 's/^"//; s/"$//')")

for format in "${formats[@]}"; do
  case $format in
    html) $MARP ;;
    *) $MARP "--$format" ;;
  esac
done

# The html keeps the image paths relative to itself, so assets/ has to sit in $out too.
mkdir -p "$out"
if [ -d assets ]; then
  cp -r assets "$out/"
fi
