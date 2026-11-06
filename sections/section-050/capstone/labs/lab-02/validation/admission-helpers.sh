#!/usr/bin/env bash
# Shared live-state checks; sourced by the three graders.
set -euo pipefail
export PATH="/usr/local/bin:$HOME/.local/bin:$PATH"
LAB_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SIGNED_IMAGE='ghcr.io/kyverno/test-verify-image@sha256:b31bfb4d0213f254d361e0079deaaebefa4f82ba7aa76ef82e90b4935ad5b105'
UNSIGNED_IMAGE='ghcr.io/kyverno/test-verify-image@sha256:74a98f0e4d750c9052f092a7f7a72de7b20f94f176a490088f7a744c76c53ea5'
PUBLIC_KEY='/tmp/ats021-capstone-050-02-signatures/audit-signing.pub'
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
fail() { echo "FAIL: $*" >&2; exit 1; }
require_policy() {
  kubectl get imagevalidatingpolicy signed-production -o json > "$WORK/policy.json"
  python3 - "$WORK/policy.json" "$LAB_DIR/manifests/audit-signing.pub" <<'PYPOLICY'
import json, pathlib, sys
policy = json.load(open(sys.argv[1]))
spec = policy['spec']
assert spec.get('validationActions') == ['Deny'], 'Use Deny'
assert spec.get('failurePolicy') == 'Fail', 'Fail closed on evaluation errors'
assert spec['matchConstraints']['namespaceSelector'] == {'matchLabels': {'environment': 'production'}}, 'Select production by label'
assert spec.get('evaluation', {}).get('background', {}).get('enabled') is False, 'Disable background evaluation'
assert spec.get('matchImageReferences') == [{'glob': '*'}], 'Match every image'
configuration = spec.get('validationConfigurations', {})
assert configuration.get('required') is True and configuration.get('verifyDigest') is True, 'Require signature and digest verification'
rules = spec['matchConstraints'].get('resourceRules', [])
assert any('' in rule.get('apiGroups', []) and 'v1' in rule.get('apiVersions', [])
           and 'pods' in rule.get('resources', [])
           and all(operation in rule.get('operations', []) or '*' in rule.get('operations', [])
                   for operation in ['CREATE', 'UPDATE']) for rule in rules), 'Cover Pod CREATE and UPDATE'
key = pathlib.Path(sys.argv[2]).read_text().strip()
assert any(attestor.get('cosign', {}).get('key', {}).get('data', '').strip() == key
           and attestor['cosign'].get('ctlog', {}).get('insecureIgnoreTlog') is True
           for attestor in spec.get('attestors', [])), 'Use the supplied test key and transparency exception'
assert any('verifyImageSignatures(' in validation.get('expression', '')
           for validation in spec.get('validations', [])), 'Verify signatures in a CEL validation'
assert policy.get('status', {}).get('conditionStatus', {}).get('ready') is True, 'Policy is not ready'
PYPOLICY
}
check_labels() {
  kubectl get namespaces starfleet starfleet-canary outpost outpost-unlabelled -o json > "$WORK/namespaces.json"
  python3 - "$WORK/namespaces.json" <<'PYLABELS'
import json, sys
expected = {'starfleet-prod':'production', 'starfleet-canary':'production', 'outpost':'development', 'outpost-unlabelled':None}
for namespace in json.load(open(sys.argv[1]))['items']:
    assert namespace['metadata'].get('labels', {}).get('environment') == expected[namespace['metadata']['name']], 'Restore namespace environment labels'
PYLABELS
}
request_pod() {
  local namespace="$1" image="$2"
  python3 - "$namespace" "$image" <<'PYPOD' > "$WORK/pod.json"
import json, sys, uuid
namespace, image = sys.argv[1:]
spec = {'serviceAccountName':'scout', 'restartPolicy':'Never', 'containers':[{'name':'scout', 'image':image}]}
print(json.dumps({'apiVersion':'v1', 'kind':'Pod', 'metadata':{'name':'signature-check-'+uuid.uuid4().hex[:12], 'namespace':namespace}, 'spec':spec}))
PYPOD
  kubectl create --dry-run=server --request-timeout=45s -f "$WORK/pod.json" -o json > "$WORK/response.json" 2> "$WORK/error.txt"
}
expect_allowed() {
  request_pod "$1" "$2" || { cat "$WORK/error.txt" >&2; fail "Admission should allow $1 / $2"; }
  python3 - "$WORK/response.json" "$1" <<'PYALLOW'
import json, sys
pod = json.load(open(sys.argv[1]))
assert pod['kind'] == 'Pod' and pod['metadata']['namespace'] == sys.argv[2]
PYALLOW
}
expect_denied() {
  if request_pod "$1" "$2"; then fail "Unsigned image was admitted in $1"; fi
  # A timeout, connection failure or unrelated admission refusal is not a signature denial.
  python3 - "$WORK/error.txt" <<'PYDENY'
import pathlib, sys
message = pathlib.Path(sys.argv[1]).read_text().lower()
assert 'signed-production' in message, 'Denial must name the signature policy'
assert 'denied' in message or 'failed validation' in message, 'No admission denial'
assert not any(error in message for error in ['timeout', 'timed out', 'deadline exceeded', 'failed calling webhook', 'connection refused', 'no such host', 'unauthorized', 'too many requests']), 'Infrastructure error is not proof of signature enforcement'
PYDENY
}
