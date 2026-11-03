#!/usr/bin/env bash
# Check: a new namespace gets a default-deny NetworkPolicy with an empty pod
# selector and both policy types. The grader creates a namespace and removes
# it at the end.
set -uo pipefail

NS="grader-generate-$$"
fail=0
trap 'kubectl delete namespace "$NS" --wait=false >/dev/null 2>&1' EXIT

kubectl create namespace "$NS" >/dev/null 2>&1 || { echo "FAIL: could not create the test namespace"; exit 1; }

found=""
for _ in $(seq 1 30); do
  found="$(kubectl -n "$NS" get networkpolicy default-deny -o json 2>/dev/null || true)"
  [ -n "$found" ] && break
  sleep 2
done

if [ -z "$found" ]; then
  echo "FAIL: the new namespace has no NetworkPolicy named default-deny"
  exit 1
fi

selector="$(printf '%s' "$found" | jq -c '.spec.podSelector')"
types="$(printf '%s' "$found" | jq -r '.spec.policyTypes | sort | join(",")')"
if [ "$selector" != "{}" ]; then
  echo "FAIL: default-deny must select all pods (podSelector {}), got $selector"
  fail=1
fi
if [ "$types" != "Egress,Ingress" ]; then
  echo "FAIL: default-deny must list Ingress and Egress, got $types"
  fail=1
fi
if [ "$fail" -eq 0 ]; then
  echo "PASS: a new namespace gets a default-deny NetworkPolicy"
fi
exit "$fail"
