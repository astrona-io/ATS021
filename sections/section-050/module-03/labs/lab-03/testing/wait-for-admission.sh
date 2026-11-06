#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# Wait for readiness and actual admission behavior, not only a controller rollout.
for attempt in $(seq 1 30); do
  if bash "$SCRIPT_DIR/../validation/validate-production-admission.sh" &&
     bash "$SCRIPT_DIR/../validation/validate-namespace-scope.sh"; then exit 0; fi
  sleep 3
done
echo 'Signature admission did not become ready' >&2
exit 1
