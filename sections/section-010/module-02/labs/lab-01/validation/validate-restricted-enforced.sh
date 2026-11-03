#!/usr/bin/env bash
# Check: starfleet enforces the restricted level. Rejects the plausible wrong
# fixes: baseline, privileged, or only warn/audit mode.
set -uo pipefail

level="$(kubectl get namespace starfleet -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}' 2>/dev/null || true)"
if [ "$level" != "restricted" ]; then
  echo "FAIL: pod-security.kubernetes.io/enforce on starfleet is '${level}', expected 'restricted'"
  exit 1
fi

echo "PASS: starfleet enforces the restricted level"
