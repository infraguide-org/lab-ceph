#!/usr/bin/env bash
# Source: https://github.com/infraguide-org/lab-ceph
# Copyright (c) 2026 infraguide.org, MIT License
#
# Writes index.json (machine-readable list of decks and files) and index.html
# (download page) into the built slides directory.
# Usage: make-index.sh <lab> <src-dir> <dist-dir> [build-yml]
# The optional build.yml (status/build.yml) adds a Build section to index.html.
set -euo pipefail

lab=$1
src=$(realpath "$2")
build=$([ -f "${4:-}" ] && realpath "$4" || true)
cd "$3"

rm -f README.*

decks='[]'
for md in "$src"/*.md; do
  name=$(basename "$md" .md)
  [ "$name" = README ] && continue
  [ -f "$name.html" ] || continue
  title=$(sed -n '/^---$/,/^---$/{s/^title: *//p;}' "$md" | head -1 | sed 's/^"//; s/"$//')
  order=$(sed -n '/^---$/,/^---$/{s/^order: *//p;}' "$md" | head -1)
  covers=${name#slides-}
  covers=${covers^}
  decks=$(jq -c --arg n "$name" --arg t "${title:-$name}" --arg c "$covers" --argjson o "${order:-999}" \
    '. + [{name: $n, title: $t, covers: $c, order: $o, html: "\($n).html", pdf: "\($n).pdf", pptx: "\($n).pptx"}]' <<<"$decks")
done

files=$(find . -type f ! -name 'index.*' | sed 's#^\./##' | sort | jq -R -s -c 'split("\n") | map(select(length > 0))')

jq -n --arg lab "$lab" --argjson decks "$(jq -c 'sort_by(.order)' <<<"$decks")" --argjson files "$files" \
  '{schema: 1, lab: $lab, decks: $decks, files: $files}' > index.json

{
  cat <<HTML
<!doctype html>
<html lang="en">
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Ceph Lab</title>
<style>
  body { font: 16px/1.5 system-ui, sans-serif; max-width: 52rem; margin: 2rem auto; padding: 0 1rem; color: #111; background: #fff; }
  img.logo { height: 44px; display: block; margin-bottom: 1.5rem; }
  table { width: 100%; border-collapse: collapse; table-layout: fixed; }
  th, td { padding: .6rem .8rem; border-bottom: 1px solid #e5e7eb; text-align: left; }
  table.decks th:nth-child(1) { width: 52%; }
  table.decks th:nth-child(n+2), table.decks td:nth-child(n+2) { width: 16%; text-align: center; }
  table.checks td:nth-child(2) { width: 25%; }
  .passed { color: #15803d; }
  .failed { color: #b91c1c; }
  .pending { color: #b45309; }
  footer { margin-top: 2rem; font-size: .8rem; color: #fff; }
  footer ::selection, footer::selection { background: #2b6cb0; color: #fff; }
  a { color: #2b6cb0; text-decoration: none; }
  a:hover { text-decoration: underline; }
</style>
<a href="https://infraguide.org"><img class="logo" src="assets/logo/logo.svg" alt="infraguide.org"></a>
<h1>Ceph Lab</h1>
<h2>Slides</h2>
<table class="decks">
  <thead><tr><th>Deck</th><th>HTML</th><th>PDF</th><th>PPTX</th></tr></thead>
  <tbody>
HTML
  jq -r '.decks[] | "    <tr><td>\(.covers | gsub("&"; "&amp;") | gsub("<"; "&lt;"))</td><td><a href=\"\(.html)\">View</a></td><td><a href=\"\(.pdf)\">Download</a></td><td><a href=\"\(.pptx)\">Download</a></td></tr>"' index.json
  cat <<HTML
  </tbody>
</table>
HTML
  if [ -n "$build" ]; then
    python3 -c 'import sys, yaml, json; json.dump(yaml.safe_load(open(sys.argv[1])), sys.stdout, default=str)' "$build" > build.json
    echo '<h2>Build</h2>'
    jq -r '"<p>\([.date, .node, .duration] | map(tostring | @html) | join(" · ")) · \([.checks[] | select(.status == "passed")] | length) of \(.checks | length) checks passed</p>"' build.json
    echo '<table class="checks">'
    echo '  <thead><tr><th>Check</th><th>Status</th></tr></thead>'
    echo '  <tbody>'
    jq -r '.checks[] | "    <tr><td>\(.text | @html)</td><td class=\"\(if .status == "passed" or .status == "failed" then .status else "pending" end)\">\(.status | @html)</td></tr>"' build.json
    echo '  </tbody>'
    echo '</table>'
    rm build.json
  fi
  echo "<footer>built <time datetime=\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\">$(date -u '+%Y-%m-%d %H:%M UTC')</time></footer>"
  echo '</html>'
} > index.html
