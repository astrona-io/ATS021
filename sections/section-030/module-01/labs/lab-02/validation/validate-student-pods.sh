#!/usr/bin/env bash
# Check the learner's persisted demonstration, then repeat an UPDATE.
set -euo pipefail
fail() { echo "FAIL: student-pods: $*"; exit 1; }
kubectl get namespacedmutatingpolicy default-team -n starfleet >/dev/null || fail "Create the policy first"
for name in scout-default scout-labelled; do
  kubectl get pod "$name" -n starfleet -o json | jq -e '.spec.serviceAccountName == "scout" and any(.spec.containers[]; .image == "ghcr.io/stefanprodan/podinfo:6.15.0")' >/dev/null || fail "$name must use service account scout and podinfo 6.15.0"
done
kubectl get pod scout-labelled -n starfleet -o json | jq -e '.metadata.labels.team == "unassigned" and .metadata.labels.app == "scout"' >/dev/null || fail "scout-labelled must keep app=scout and get team=unassigned"
kubectl get pod scout-default -n starfleet -o json | jq -e '.metadata.labels.team == "navigation" and .metadata.annotations.proof == "retained"' >/dev/null || fail "Change scout-default to team=navigation, then annotate proof=retained"
kubectl annotate pod scout-default -n starfleet grader-check=retained --overwrite >/dev/null || fail "Could not send another UPDATE"
[ "$(kubectl get pod scout-default -n starfleet -o jsonpath='{.metadata.labels.team}')" = navigation ] || fail "A later UPDATE reset team"
echo "PASS: student-pods"
