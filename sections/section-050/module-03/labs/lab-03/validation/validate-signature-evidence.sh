#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/admission-helpers.sh"
cmp "$PUBLIC_KEY" "$LAB_DIR/manifests/audit-signing.pub" || fail 'Restore the supplied public key'
kubectl -n starfleet get configmap signature-candidates -o json > "$WORK/candidates.json"
kubectl -n starfleet get configmap signature-audit -o json > "$WORK/audit.json"
python3 - "$WORK/candidates.json" "$WORK/audit.json" "$SIGNED_IMAGE" "$UNSIGNED_IMAGE" <<'PYAUDIT'
import json, sys
candidates = json.load(open(sys.argv[1]))['data']
audit = json.load(open(sys.argv[2]))['data']
signed, unsigned = sys.argv[3:]
assert candidates == {'scout-image': signed, 'probe-image': unsigned}, 'Keep the supplied candidates'
assert audit.get('signed-image') == candidates['scout-image'], 'Wrong signed-image answer'
assert audit.get('unsigned-image') == candidates['probe-image'], 'Wrong unsigned-image answer'
PYAUDIT
python3 "$SCRIPT_DIR/verify-candidates.py" "$PUBLIC_KEY" "$SIGNED_IMAGE" "$UNSIGNED_IMAGE"
echo 'PASS: signature-evidence'
