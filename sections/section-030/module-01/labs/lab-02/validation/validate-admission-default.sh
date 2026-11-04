#!/usr/bin/env bash
# Check real CREATE and UPDATE admission, including removal and namespace scope.
set -euo pipefail
fail() { echo "FAIL: admission-default: $*"; exit 1; }
kubectl get namespacedmutatingpolicy default-team -n starfleet >/dev/null || fail "Create the namespaced policy"
PROBE="grader-team-${RANDOM}"
cleanup() {
  kubectl delete pod "$PROBE" -n starfleet --ignore-not-found --wait=false >/dev/null 2>&1 || true
  kubectl delete pod "$PROBE" -n outpost --ignore-not-found --wait=false >/dev/null 2>&1 || true
}
trap cleanup EXIT
pod_manifest() {
  jq -n --arg name "$PROBE" --arg namespace "$1" '{apiVersion:"v1",kind:"Pod",metadata:{name:$name,namespace:$namespace,labels:{app:"probe"}},spec:{serviceAccountName:"scout",containers:[{name:"scout",image:"ghcr.io/stefanprodan/podinfo:6.15.0",resources:{limits:{cpu:"100m",memory:"64Mi"}}}]}}'
}
# Retry only policy propagation, and always require successful API responses.
for attempt in $(seq 1 30); do
  admitted="$(pod_manifest starfleet | kubectl create --dry-run=server -f - -o json)" || fail "CREATE request failed"
  if [ "$(printf '%s' "$admitted" | jq -r '.metadata.labels.team')" = unassigned ]; then break; fi
  [ "$attempt" -lt 30 ] || fail "CREATE did not add team=unassigned"
  sleep 2
done
pod_manifest starfleet | kubectl create -f - >/dev/null || fail "Could not create proof Pod"
[ "$(kubectl get pod "$PROBE" -n starfleet -o jsonpath='{.metadata.labels.team}')" = unassigned ] || fail "Stored Pod has no default"
# Removing the label makes it absent in an UPDATE request. CREATE-only policies fail.
kubectl label pod "$PROBE" -n starfleet team- >/dev/null || fail "Label removal UPDATE failed"
[ "$(kubectl get pod "$PROBE" -n starfleet -o jsonpath='{.metadata.labels.team}')" = unassigned ] || fail "UPDATE did not restore the missing label"
kubectl label pod "$PROBE" -n starfleet team=navigation --overwrite >/dev/null || fail "Human label UPDATE failed"
kubectl annotate pod "$PROBE" -n starfleet proof=retained --overwrite >/dev/null || fail "Annotation UPDATE failed"
[ "$(kubectl get pod "$PROBE" -n starfleet -o jsonpath='{.metadata.labels.team}')" = navigation ] || fail "UPDATE overwrote the person's value"
[ "$(kubectl get pod "$PROBE" -n starfleet -o jsonpath='{.metadata.labels.app}')" = probe ] || fail "Unrelated label was lost"
admitted="$(pod_manifest outpost | kubectl create --dry-run=server -f - -o json)" || fail "outpost CREATE failed"
printf '%s' "$admitted" | jq -e '.metadata.labels | has("team") | not' >/dev/null || fail "Policy affected outpost"
pod_manifest outpost | kubectl create -f - >/dev/null || fail "outpost Pod could not be created"
kubectl annotate pod "$PROBE" -n outpost proof=outside --overwrite >/dev/null || fail "outpost UPDATE failed"
kubectl get pod "$PROBE" -n outpost -o json | jq -e '.metadata.labels | has("team") | not' >/dev/null || fail "UPDATE affected outpost"
echo "PASS: admission-default"
