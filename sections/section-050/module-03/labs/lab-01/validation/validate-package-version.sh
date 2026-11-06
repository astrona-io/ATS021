#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/live-inventory.sh"
expected=$(jq -er '[.components[] | select(.name == "busybox") | .version] | unique | if length == 1 then .[0] else error("busybox version is ambiguous") end' "$WORK/scout.cdx.json")
given=$(kubectl -n starfleet get configmap sbom-audit -o json | jq -er '.data["scout-busybox-version"]')
[ "$given" = "$expected" ] || { echo 'FAIL: package-version: answer differs from live inventory'; exit 1; }
echo 'PASS: package-version'
