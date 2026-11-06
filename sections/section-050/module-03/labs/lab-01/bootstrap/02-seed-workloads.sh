#!/usr/bin/env bash
# Seed the inventory to inspect; do not create answers or SBOMs.
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
kubectl apply -f "$SCRIPT_DIR/../manifests/lab-start.yaml"
kubectl -n starfleet rollout status deployment/scout --timeout=180s
kubectl -n starfleet rollout status deployment/probe --timeout=180s
mkdir -p /tmp/ats021-050-03-audit
rm -f /tmp/ats021-050-03-audit/scout.cdx.json
