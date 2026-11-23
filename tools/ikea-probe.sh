#!/usr/bin/env bash
# Re-run the IKEA feasibility check from the 2026-11-19 research.
# Usage: tools/ikea-probe.sh "malm bed" [country] [lang]
# Prints top search hits, then for the first hit: listed measurements, GLB URLs,
# and the GLB bounding box (needs node/npx). Personal use only; don't bulk-scrape.
set -euo pipefail
q="${1:-malm bed}"; cc="${2:-gb}"; lang="${3:-en}"
work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT
ua="Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/130 Mobile Safari/537.36"

curl -sS -m 30 -A "$ua" -G "https://sik.search.blue.cdtapps.com/$cc/$lang/search-result-page" \
  --data-urlencode "q=$q" -d size=3 -d types=PRODUCT -o "$work/search.json"
url=$(python3 -I - "$work/search.json" <<'EOF'
import json,sys
items=json.load(open(sys.argv[1]))["searchResultPage"]["products"]["main"]["items"]
for i in items:
    p=i["product"]; print(p["name"],"|",p["typeName"],"|",p.get("itemMeasureReferenceText"),"|",p["salesPrice"].get("numeral"),"|",p["pipUrl"],file=sys.stderr)
print(items[0]["product"]["pipUrl"])
EOF
)
echo "== product page: $url"
curl -sS -m 30 -A "$ua" "$url" -o "$work/pip.html"

python3 -I - "$work/pip.html" <<'EOF'
import re,sys
h=open(sys.argv[1],encoding="utf-8").read()
print("== measurements (first labelled values on page):")
for m in re.finditer(r'pipf-measurements-tab__measurement[^>]*>(.*?)</', h):
    t=re.sub(r'<[^>]+>',' ',m.group(1)).strip()
    if t: print("  ",t)
EOF

echo "== GLB URLs:"; grep -oE 'https://web-api\.ikea\.com/dimma/assets/[^"]+\.glb' "$work/pip.html" | sort -u
glb=$(grep -oE 'https://web-api\.ikea\.com/dimma/assets/[^"]+/isp1/glb/[^"]+\.glb' "$work/pip.html" | head -1 || true)
if [[ -n "$glb" ]] && command -v npx >/dev/null; then
  curl -sS -m 60 "$glb" -o "$work/m.glb"
  echo "== isp1 bbox (metres):"; npx -y @gltf-transform/cli@4 inspect "$work/m.glb" 2>/dev/null | grep -A3 bboxMin | tail -2
fi
