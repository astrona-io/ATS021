#!/usr/bin/env bash
# Check: ci-deployer has nothing beyond Deployments and Services in orbit.
# Rejects the plausible wrong fixes: keeping cluster-admin, binding admin or
# edit, a wildcard Role, or a ClusterRoleBinding.
set -uo pipefail

SA="system:serviceaccount:orbit:ci-deployer"
fail=0

expect_no() {
  local description="$1"
  shift
  local answer
  answer="$(kubectl auth can-i "$@" --as="$SA" 2>/dev/null || true)"
  if [ "$answer" != "no" ]; then
    echo "FAIL: ci-deployer is allowed to $description"
    fail=1
  fi
}

expect_no "read secrets in orbit" get secrets -n orbit
expect_no "create pods in orbit" create pods -n orbit
expect_no "do anything in orbit" '*' '*' -n orbit
expect_no "list deployments in default" list deployments.apps -n default
expect_no "list deployments in every namespace" list deployments.apps --all-namespaces
expect_no "delete nodes" delete nodes
expect_no "create clusterrolebindings" create clusterrolebindings

if kubectl -n orbit get secrets --as="$SA" >/dev/null 2>&1; then
  echo "FAIL: the API server let ci-deployer list secrets in orbit"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: ci-deployer has only Deployment and Service rights in orbit"
fi
exit "$fail"
