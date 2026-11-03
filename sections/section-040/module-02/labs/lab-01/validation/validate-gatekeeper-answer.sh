#!/usr/bin/env bash
# Check: the key owner-label in the ConfigMap auditor-answers lists the Deployments (namespace/name) in status.violations of the Constraint deployments-need-owner.
set -uo pipefail

fail=0

# normalize: sorts a comma or space separated list and removes duplicates
normalize() {
  printf "%s" "$1" | tr ", " "

" | sed "/^\$/d" | sort -u | paste -sd, -
}
# answer_of <key>: prints the value of a key in the ConfigMap auditor-answers
answer_of() {
  kubectl -n starfleet get configmap auditor-answers -o "jsonpath={.data.$1}" 2>/dev/null
}
# check_list <key> <live list>
check_list() {
  local key="$1" live="$2" given
  given="$(normalize "$(answer_of "$key")")"
  if [ -z "$live" ]; then
    echo "FAIL: the cluster reports no objects for $key. The violating workloads must stay as they are."
    fail=1
  elif [ "$given" != "$live" ]; then
    echo "FAIL: $key is [$given] but the live evidence lists [$live]"
    fail=1
  fi
}

if ! kubectl -n starfleet get configmap auditor-answers >/dev/null 2>&1; then
  echo "FAIL: the ConfigMap auditor-answers does not exist in starfleet"
  exit 1
fi
live="$(kubectl get k8srequiredlabels deployments-need-owner -o json 2>/dev/null | jq -r '.status.violations[]? | select(.kind == "Deployment") | "\(.namespace)/\(.name)"' | sort -u | paste -sd, -)"
check_list owner-label "$live"
if [ "$fail" -eq 0 ]; then
  echo "PASS: the Gatekeeper answer matches the live Constraint status"
fi
exit "$fail"
