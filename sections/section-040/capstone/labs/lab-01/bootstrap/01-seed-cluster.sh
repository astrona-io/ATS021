#!/usr/bin/env bash
# Starting state for the "Audit Trails And Compliance Evidence" capstone
# (`ats-021-capstone-040`). Environment only: the learner writes the answers.
# This script:
#   1. installs Kyverno 1.19.1 and Gatekeeper 3.23.1 and waits for them,
#   2. applies the Starfleet workloads, two Kyverno ClusterPolicies in Audit
#      mode and one Gatekeeper template and Constraint in dryrun mode,
#   3. waits for the first reports. Audit logging stays off; the learner turns
#      it on.
set -euo pipefail

KYVERNO_VERSION="v1.19.1"
GATEKEEPER_VERSION="v3.23.1"
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[lab] Installing Kyverno ${KYVERNO_VERSION}..."
kubectl create -f "https://github.com/kyverno/kyverno/releases/download/${KYVERNO_VERSION}/install.yaml"
for d in kyverno-admission-controller kyverno-background-controller kyverno-reports-controller kyverno-cleanup-controller; do
  kubectl -n kyverno rollout status "deployment/$d" --timeout=300s
done
for i in $(seq 1 60); do
  if kubectl get validatingwebhookconfiguration kyverno-resource-validating-webhook-cfg >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

echo "[lab] Installing Gatekeeper ${GATEKEEPER_VERSION}..."
kubectl apply -f "https://raw.githubusercontent.com/open-policy-agent/gatekeeper/${GATEKEEPER_VERSION}/deploy/gatekeeper.yaml"
kubectl -n gatekeeper-system rollout status deployment/gatekeeper-controller-manager --timeout=300s
kubectl -n gatekeeper-system rollout status deployment/gatekeeper-audit --timeout=300s
kubectl wait --for=condition=Established crd/constrainttemplates.templates.gatekeeper.sh --timeout=120s

echo "[lab] Applying the Starfleet workloads..."
kubectl apply -f "$DIR/manifests/lab-start.yaml"
for d in scout probe shuttle relay beacon; do
  kubectl -n starfleet rollout status "deployment/$d" --timeout=180s
done
kubectl -n outpost rollout status deployment/drifter --timeout=180s

echo "[lab] Applying the Kyverno policies (Audit mode)..."
# The webhook can need a moment before it accepts policies.
for i in $(seq 1 30); do
  if kubectl apply -f "$DIR/manifests/kyverno-policies.yaml"; then
    break
  fi
  sleep 3
done

echo "[lab] Applying the Gatekeeper template and Constraint (dryrun)..."
kubectl apply -f "$DIR/manifests/gatekeeper-owner-label.yaml"
for i in $(seq 1 60); do
  if kubectl get crd k8srequiredlabels.constraints.gatekeeper.sh >/dev/null 2>&1; then
    break
  fi
  sleep 2
done
kubectl wait --for=condition=Established crd/k8srequiredlabels.constraints.gatekeeper.sh --timeout=120s
for i in $(seq 1 30); do
  if kubectl apply -f "$DIR/manifests/gatekeeper-owner-constraint.yaml"; then
    break
  fi
  sleep 3
done

echo "[lab] Waiting for the first Kyverno reports and Gatekeeper audit results..."
for i in $(seq 1 60); do
  if kubectl get k8srequiredlabels deployments-need-owner -o jsonpath='{.status.totalViolations}' 2>/dev/null | grep -q '^[0-9]' \
     && [ "$(kubectl get policyreport -A --no-headers 2>/dev/null | wc -l | tr -d ' ')" -ge 10 ]; then
    break
  fi
  sleep 5
done
echo "[lab] Ready."
