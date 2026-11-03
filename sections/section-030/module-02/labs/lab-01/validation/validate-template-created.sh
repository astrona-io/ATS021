#!/usr/bin/env bash
# Check: the ConstraintTemplate k8sdisallowedtags compiles and Gatekeeper
# created its constraint kind.
set -uo pipefail

fail=0

created=""
for _ in $(seq 1 20); do
  created="$(kubectl get constrainttemplate k8sdisallowedtags -o jsonpath='{.status.created}' 2>/dev/null || true)"
  [ "$created" = "true" ] && break
  sleep 3
done
if [ "$created" != "true" ]; then
  echo "FAIL: ConstraintTemplate k8sdisallowedtags has status.created=${created:-unset}; read status.byPod[0].errors"
  fail=1
fi

if ! kubectl get crd k8sdisallowedtags.constraints.gatekeeper.sh >/dev/null 2>&1; then
  echo "FAIL: the CustomResourceDefinition k8sdisallowedtags.constraints.gatekeeper.sh does not exist"
  fail=1
fi

kind="$(kubectl get constrainttemplate k8sdisallowedtags -o jsonpath='{.spec.crd.spec.names.kind}' 2>/dev/null || true)"
if [ "$kind" != "K8sDisallowedTags" ]; then
  echo "FAIL: the template must keep the kind K8sDisallowedTags, got ${kind:-none}"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: the template compiles and its constraint kind exists"
fi
exit "$fail"
