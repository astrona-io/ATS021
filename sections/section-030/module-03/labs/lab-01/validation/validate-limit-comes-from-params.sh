#!/usr/bin/env bash
# Check: the limit is read from the replica-limits ConfigMap. The policy has
# a paramKind of ConfigMap, its expression reads params, and every binding
# points at replica-limits. The ConfigMap itself must be unchanged.
set -uo pipefail

fail=0

policies="$(kubectl get validatingadmissionpolicies -o json)"
bindings="$(kubectl get validatingadmissionpolicybindings -o json)"

policy_ok="$(printf '%s' "$policies" | jq '[.items[]
  | select(.spec.paramKind.kind == "ConfigMap" and .spec.paramKind.apiVersion == "v1")
  | select(any(.spec.validations[]; (.expression | test("params\\.data"))))] | length')"
if [ "${policy_ok:-0}" -lt 1 ]; then
  echo "FAIL: no ValidatingAdmissionPolicy has paramKind v1/ConfigMap and an expression that reads params.data"
  fail=1
fi

wrong="$(printf '%s' "$bindings" | jq '[.items[] | select(.spec.paramRef.name != "replica-limits")] | length')"
total="$(printf '%s' "$bindings" | jq '.items | length')"
if [ "${total:-0}" -lt 1 ] || [ "${wrong:-1}" -ne 0 ]; then
  echo "FAIL: every ValidatingAdmissionPolicyBinding must set paramRef.name to replica-limits"
  fail=1
fi

max="$(kubectl -n starfleet get configmap replica-limits -o jsonpath='{.data.maxReplicas}' 2>/dev/null || true)"
if [ "$max" != "5" ]; then
  echo "FAIL: the ConfigMap replica-limits must keep maxReplicas \"5\", found \"${max}\""
  fail=1
fi

# A hard-coded 5 would make the ConfigMap pointless.
hard="$(printf '%s' "$policies" | jq '[.items[].spec.validations[].expression | select(test("replicas <= 5"))] | length')"
if [ "${hard:-0}" -ne 0 ]; then
  echo "FAIL: the expression compares with a fixed 5; read params.data.maxReplicas instead"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: the limit comes from the replica-limits ConfigMap"
fi
exit "$fail"
