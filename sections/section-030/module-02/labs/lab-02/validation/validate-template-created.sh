#!/usr/bin/env bash
# Check: the ConstraintTemplate k8sstarfleetworkloadrules compiles and
# Gatekeeper created its constraint kind K8sStarfleetWorkloadRules.
set -uo pipefail

fail=0

created=""
for _ in $(seq 1 20); do
  created="$(kubectl get constrainttemplate k8sstarfleetworkloadrules -o jsonpath='{.status.created}' 2>/dev/null || true)"
  [ "$created" = "true" ] && break
  sleep 3
done
if [ "$created" != "true" ]; then
  echo "FAIL: ConstraintTemplate k8sstarfleetworkloadrules has status.created=${created:-unset}; read status.byPod[0].errors"
  fail=1
fi

if ! kubectl get crd k8sstarfleetworkloadrules.constraints.gatekeeper.sh >/dev/null 2>&1; then
  echo "FAIL: the CustomResourceDefinition k8sstarfleetworkloadrules.constraints.gatekeeper.sh does not exist"
  fail=1
fi

kind="$(kubectl get constrainttemplate k8sstarfleetworkloadrules -o jsonpath='{.spec.crd.spec.names.kind}' 2>/dev/null || true)"
if [ "$kind" != "K8sStarfleetWorkloadRules" ]; then
  echo "FAIL: the template must use the kind K8sStarfleetWorkloadRules, got ${kind:-none}"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: the template compiles and its constraint kind exists"
fi
exit "$fail"
