#!/usr/bin/env bash
# Check: the key kyverno-failing in the ConfigMap auditor-answers lists the Deployments (namespace/name) that fail at least one Kyverno policy in the live PolicyReports.
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

kyverno_failures() {
  kubectl get policyreport -A -o json | jq -r '.items[] | .scope as $s | select($s.kind == "Deployment") | select(any(.results[]?; .result == "fail")) | "\($s.namespace)/\($s.name)"' | sort -u | paste -sd, -
}
if ! kubectl -n starfleet get configmap auditor-answers >/dev/null 2>&1; then
  echo "FAIL: the ConfigMap auditor-answers does not exist in starfleet"
  exit 1
fi
check_list kyverno-failing "$(kyverno_failures)"
if [ "$fail" -eq 0 ]; then
  echo "PASS: the Kyverno answer matches the live policy reports"
fi
exit "$fail"
