#!/usr/bin/env bash
# Environment prep for the "Enforce Constraints With Gatekeeper And Rego"
# playground (`ats-021-playground-030-02`).
#
# Environment preparation only — there is no task and no grading. This script:
#   1. installs Gatekeeper 3.23.1 from its release manifest,
#   2. waits until the controller manager and audit are ready,
#   3. applies the Starfleet workloads and one ConstraintTemplate whose Rego
#      does not compile (on purpose).
# No working ConstraintTemplate and no Constraint are created.
set -euo pipefail

GATEKEEPER_VERSION="v3.23.1"

echo "[playground] Installing Gatekeeper ${GATEKEEPER_VERSION}..."
kubectl apply -f "https://raw.githubusercontent.com/open-policy-agent/gatekeeper/${GATEKEEPER_VERSION}/deploy/gatekeeper.yaml"
kubectl -n gatekeeper-system rollout status deployment/gatekeeper-controller-manager --timeout=300s
kubectl -n gatekeeper-system rollout status deployment/gatekeeper-audit --timeout=300s
kubectl wait --for=condition=Established crd/constrainttemplates.templates.gatekeeper.sh --timeout=120s

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "[playground] Applying the Starfleet workloads..."
kubectl apply -f "$SCRIPT_DIR/../manifests/starfleet.yaml"
for d in scout probe shuttle; do
  kubectl -n starfleet rollout status "deployment/$d" --timeout=180s
done
kubectl -n outpost rollout status deployment/drifter --timeout=180s

echo "[playground] Applying the broken ConstraintTemplate..."
kubectl apply -f "$SCRIPT_DIR/../manifests/broken-template.yaml"
echo "[playground] Ready."
