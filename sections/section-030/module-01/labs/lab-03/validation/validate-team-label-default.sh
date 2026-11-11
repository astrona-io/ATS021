#!/usr/bin/env bash
# Check: a pod in starfleet gets team=unassigned when it has no team label, keeps its own team label, and outpost pods are not changed.
set -uo pipefail

fail=0

pod_manifest() {
  # pod_manifest <name> <resources yaml, indented 8 spaces> [extra labels]
  local name="$1" resources="$2" labels="${3:-}"
  cat <<YAML
apiVersion: v1
kind: Pod
metadata:
  name: $name
  labels:
    app: grader
$labels
spec:
  containers:
    - name: test
      image: curlimages/curl:8.22.0
      command: ["sh", "-c", "sleep 3600"]
$resources
YAML
}
BOTH="      resources:
        limits:
          cpu: 50m
          memory: 32Mi"
NONE=""


label_of() {
  # label_of <namespace> <manifest>: prints the team label of the pod as admitted (dry-run).
  printf "%s" "$2" | kubectl create -n "$1" --dry-run=server -o json -f - 2>/dev/null | jq -r ".metadata.labels.team // \"none\"" 2>/dev/null
}

got=""
for _ in $(seq 1 15); do
  got="$(label_of starfleet "$(pod_manifest grader-nolabel "$BOTH")")"
  [ "$got" = "unassigned" ] && break
  sleep 3
done
[ "$got" = "unassigned" ] || { echo "FAIL: a pod without team label got team=$got, expected unassigned"; fail=1; }

got="$(label_of starfleet "$(pod_manifest grader-ownlabel "$BOTH" "    team: blue")")"
[ "$got" = "blue" ] || { echo "FAIL: a pod with team=blue ended with team=$got, the rule must not overwrite it"; fail=1; }

got="$(label_of outpost "$(pod_manifest grader-outpost "$NONE")")"
[ "$got" = "none" ] || { echo "FAIL: a pod in outpost got team=$got, the rule must only change starfleet"; fail=1; }
if [ "$fail" -eq 0 ]; then
  echo "PASS: team label default is added only when missing, only in starfleet"
fi
exit "$fail"
