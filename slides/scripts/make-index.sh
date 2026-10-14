#!/usr/bin/env bash
# Source: https://github.com/infraguide-org/lab-ceph
# Copyright (c) 2026 infraguide.org, MIT License
#
# Writes index.json (machine-readable list of decks and files) and index.html
# (download page) into the built slides directory.
# Usage: make-index.sh <lab> <src-dir> <dist-dir> [build-yml] [env-yaml]
# The optional build.yml (status/build.yml) adds a Build section to index.html,
# the optional env.yaml (conf/env.yaml) adds a Hosts section.
set -euo pipefail

lab=$1
src=$(realpath "$2")
build=$([ -f "${4:-}" ] && realpath "$4" || true)
env=$([ -f "${5:-}" ] && realpath "$5" || true)
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
  table.hosts th:nth-child(n+2), table.hosts td:nth-child(n+2) { width: 16%; }
  .note { color: #6b7280; font-weight: 400; font-size: .85rem; }
  .summary { display: inline-block; margin-left: .5rem; padding: .15rem .75rem; border-radius: 999px; font-weight: 600; border: 1px solid; }
  .summary.ok { color: #15803d; background: #dcfce7; border-color: #86efac; }
  .summary.bad { color: #b91c1c; background: #fee2e2; border-color: #fca5a5; }
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
  if [ -n "$env" ]; then
    python3 - "$env" > hosts.json <<'PY'
import json, sys, yaml

servers = yaml.safe_load(open(sys.argv[1]))["server_conf"]
base = min((s["domain"] for s in servers), key=lambda d: (d.count("."), len(d)))

def disks(values):
    runs = []
    for v in values or []:
        if runs and runs[-1][0] == v:
            runs[-1][1] += 1
        else:
            runs.append([v, 1])
    return " + ".join(f"{n}×{v}" if n > 1 else str(v) for v, n in runs) + " GB" if runs else "–"

def host(s):
    airgapped = {True: "yes", "soft": "soft"}.get(s.get("airgapped"), "–")
    return {"name": s["hostname"], "cpu": s["cpu"], "ram": f"{round(s['ram'] / 1024)} GB", "disks": disks(s.get("disks")), "airgapped": airgapped}

servers.sort(key=lambda s: s["id"])
json.dump({
    "base": base,
    "infrastructure": [host(s) for s in servers if s["domain"] == base],
    "lab": [host(s) for s in servers if s["domain"].endswith("." + base)],
}, sys.stdout)
PY
    echo '<h2>Hosts</h2>'
    for group in infrastructure lab; do
      jq -r --arg g "$group" '(if $g == "lab" then "Lab environment <span class=\"note\">the hosts you work with, *.\(.base | @html)</span>" else "Infrastructure <span class=\"note\">supporting services, \(.base | @html)</span>" end) as $t | "<h3>\($t)</h3>\n<table class=\"hosts\">\n  <thead><tr><th>Host</th><th>vCPU</th><th>RAM</th><th>Disks</th><th>Air-gapped</th></tr></thead>\n  <tbody>", (.[$g][] | "    <tr><td><code>\(.name | @html)</code></td><td>\(.cpu)</td><td>\(.ram)</td><td>\(.disks | @html)</td><td>\(.airgapped)</td></tr>"), "  </tbody>\n</table>"' hosts.json
    done
    rm hosts.json
  fi
  if [ -n "$build" ]; then
    python3 -c 'import sys, yaml, json; json.dump(yaml.safe_load(open(sys.argv[1])), sys.stdout, default=str)' "$build" > build.json
    echo '<h2>Build</h2>'
    jq -r '([.checks[] | select(.status == "passed")] | length) as $ok | (.checks | length) as $all | "<p>\([.date, .node, .duration] | map(tostring | @html) | join(" · ")) <span class=\"summary \(if $ok == $all then "ok" else "bad" end)\">\($ok) of \($all) checks passed</span></p>"' build.json
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
