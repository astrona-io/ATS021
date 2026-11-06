#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/live-inventory.sh"
expected=$(for deployment in scout probe; do
  if jq -e 'any(.components[]; .name == "bash")' "$WORK/$deployment.cdx.json" >/dev/null; then
    echo "$deployment"
  fi
done | sort | paste -sd, -)
[ -n "$expected" ] || { echo 'FAIL: package-owners: no bash inventory found'; exit 1; }
given=$(kubectl -n starfleet get configmap sbom-audit -o json | jq -er '.data["bash-deployments"]')
[ "$given" = "$expected" ] || { echo 'FAIL: package-owners: use sorted, comma-separated Deployment names'; exit 1; }
echo 'PASS: package-owners'
