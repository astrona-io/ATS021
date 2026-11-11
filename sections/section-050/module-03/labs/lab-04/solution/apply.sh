#!/usr/bin/env bash
set -euo pipefail
EVIDENCE=/tmp/ats021-sbom-scan
ARGS=()
for name in clean vulnerable; do
  status=0
  trivy sbom --cache-dir "$EVIDENCE/cache" --skip-db-update \
    --severity HIGH,CRITICAL --ignorefile /dev/null --exit-code 1 \
    --format json --output "$EVIDENCE/$name.scan.json" "$EVIDENCE/$name.cdx.json" || status=$?
  [ "$status" -le 1 ] && [ -s "$EVIDENCE/$name.scan.json" ] || exit 1
  count=$(jq '[.Results[]? | .Vulnerabilities[]?] | length' "$EVIDENCE/$name.scan.json")
  ARGS+=("--from-literal=$name-exit-code=$status" "--from-literal=$name-findings=$count")
done
kubectl -n starfleet create configmap scan-decisions "${ARGS[@]}" --dry-run=client -o yaml | kubectl apply -f -
