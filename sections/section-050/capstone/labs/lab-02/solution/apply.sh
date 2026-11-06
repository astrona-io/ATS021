#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/../validation/admission-helpers.sh"
# Build the answer only after live verification of both immutable candidates.
python3 "$LAB_DIR/validation/verify-candidates.py" "$PUBLIC_KEY" "$SIGNED_IMAGE" "$UNSIGNED_IMAGE"
python3 - "$SIGNED_IMAGE" "$UNSIGNED_IMAGE" <<'PYSOLUTION' > "$WORK/audit.json"
import json, sys
print(json.dumps({'apiVersion':'v1', 'kind':'ConfigMap',
                  'metadata':{'name':'signature-audit', 'namespace':'starfleet'},
                  'data':{'signed-image':sys.argv[1], 'unsigned-image':sys.argv[2]}}))
PYSOLUTION
kubectl apply -f "$WORK/audit.json"
kubectl apply -f "$SCRIPT_DIR/imagevalidatingpolicy-signed-production.yaml"
kubectl apply -f "$SCRIPT_DIR/solution.yaml"
