#!/usr/bin/env bash
# Compare the learner's saved policy with live state, then test trusted fixtures.
set -euo pipefail
export PATH="/usr/local/bin:$HOME/.local/bin:$PATH"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { echo "FAIL: policy-offline: $*"; exit 1; }
LIVE="$(kubectl get namespacedmutatingpolicy default-team -n starfleet -o json)" || fail "Create the namespaced policy"
[ "$(printf '%s' "$LIVE" | jq -r '.apiVersion')" = policies.kyverno.io/v1 ] || fail "Use policies.kyverno.io/v1"
printf '%s' "$LIVE" | jq -e '.spec.matchConstraints.resourceRules | any(.apiGroups == [""] and .apiVersions == ["v1"] and .resources == ["pods"] and (.operations | index("CREATE")) and (.operations | index("UPDATE")))' >/dev/null || fail "Match core v1 Pods on CREATE and UPDATE"
printf '%s' "$LIVE" | jq -e '.spec.evaluation.admission.enabled != false and .spec.evaluation.mutateExisting.enabled != true' >/dev/null || fail "Enable admission and disable mutation of existing resources"
[ -f /tmp/kyverno-team-test/policy.yaml ] || fail "Save /tmp/kyverno-team-test/policy.yaml"
SAVED="$(kubectl apply --dry-run=server -f /tmp/kyverno-team-test/policy.yaml -o json)" || fail "Saved policy is not valid YAML"
for field in '.apiVersion' '.kind' '.metadata.name' '.metadata.namespace' '.spec'; do
  [ "$(printf '%s' "$LIVE" | jq -S "$field")" = "$(printf '%s' "$SAVED" | jq -S "$field")" ] || fail "Saved policy differs from live policy: $field"
done
# No `grep -q` here: with pipefail it exits on the first line and the CLI gets
# SIGPIPE while printing the rest of its output, which fails the pipeline.
kyverno version | grep 'Version: 1.19.1$' >/dev/null || fail "Use the installed CLI 1.19.1"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cp "$DIR/manifests/offline/"* "$WORK/"
cp /tmp/kyverno-team-test/policy.yaml "$WORK/policy.yaml"
kyverno apply "$WORK/policy.yaml" --resource "$WORK/pods.yaml" > "$WORK/apply.log" 2>&1 || { cat "$WORK/apply.log"; fail "kyverno apply failed"; }
kyverno test "$WORK" --require-tests || fail "Offline expected resources do not match"
echo "PASS: policy-offline"
