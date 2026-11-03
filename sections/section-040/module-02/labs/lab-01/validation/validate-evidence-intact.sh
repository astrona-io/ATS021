#!/usr/bin/env bash
# Check: the learner reported the problems and did not repair them or weaken the evidence sources.
set -uo pipefail

fail=0

for policy in require-limits disallow-latest-tag; do
  action="$(kubectl get clusterpolicy "$policy" -o jsonpath='{.spec.rules[0].validate.failureAction}' 2>/dev/null)"
  if [ "$action" != "Audit" ]; then
    echo "FAIL: the ClusterPolicy $policy has failureAction '$action', expected Audit"
    fail=1
  fi
done

action="$(kubectl get k8srequiredlabels deployments-need-owner -o jsonpath='{.spec.enforcementAction}' 2>/dev/null)"
if [ "$action" != "dryrun" ]; then
  echo "FAIL: the Constraint deployments-need-owner has enforcementAction '$action', expected dryrun"
  fail=1
fi

# The violating workloads must still violate: no limits on probe and drifter,
# the latest tag on relay, no owner label on probe and drifter.
probe_limits="$(kubectl -n starfleet get deploy probe -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}' 2>/dev/null)"
drifter_limits="$(kubectl -n outpost get deploy drifter -o jsonpath='{.spec.template.spec.containers[0].resources.limits.cpu}' 2>/dev/null)"
relay_image="$(kubectl -n starfleet get deploy relay -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)"
probe_owner="$(kubectl -n starfleet get deploy probe -o jsonpath='{.metadata.labels.owner}' 2>/dev/null)"
drifter_owner="$(kubectl -n outpost get deploy drifter -o jsonpath='{.metadata.labels.owner}' 2>/dev/null)"
if [ -n "$probe_limits" ] || [ -n "$drifter_limits" ] || [ -n "$probe_owner" ] || [ -n "$drifter_owner" ] || [ "${relay_image##*:}" != "latest" ]; then
  echo "FAIL: a violating workload (probe, drifter or relay) was repaired or deleted. Report the problems, do not fix them."
  fail=1
fi

NODE="$(kubectl get nodes -l node-role.kubernetes.io/control-plane -o jsonpath='{.items[0].metadata.name}')"
if ! kubectl -n kube-system get pod "kube-apiserver-${NODE}" -o jsonpath='{.spec.containers[0].command}' 2>/dev/null | grep -q -- '--audit-log-path'; then
  echo "FAIL: the kube-apiserver no longer has audit logging turned on"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: policies, Constraint, workloads and audit logging are unchanged"
fi
exit "$fail"
