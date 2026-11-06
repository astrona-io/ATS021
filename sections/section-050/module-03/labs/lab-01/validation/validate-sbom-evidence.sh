#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/live-inventory.sh"
EVIDENCE=/tmp/ats021-050-03-audit/scout.cdx.json
[ -s "$EVIDENCE" ] || { echo 'FAIL: sbom-evidence: missing file'; exit 1; }
# Check format and shape, then compare image identity and the complete package
# inventory with a fresh report. Do not compare random BOM refs or timestamps.
jq -e '.bomFormat == "CycloneDX" and (.specVersion | type == "string") and
  (.version | type == "number") and (.metadata.component.type == "container") and
  (.components | type == "array" and length > 0) and
  all(.components[]; (.name | type == "string") and (.type | type == "string"))' "$EVIDENCE" >/dev/null
canonical_inventory() {
  jq -S '{bomFormat, specVersion, image: (.metadata.component | {type,name,version,purl,hashes,properties}),
    components: ([.components[] | {type,name,version,purl,hashes,properties}] | sort_by(.purl,.name,.version))}' "$1"
}
canonical_inventory "$WORK/scout.cdx.json" > "$WORK/expected.json"
canonical_inventory "$EVIDENCE" > "$WORK/given.json"
cmp -s "$WORK/expected.json" "$WORK/given.json" || { echo 'FAIL: sbom-evidence: inventory or image differs'; exit 1; }
echo 'PASS: sbom-evidence'
