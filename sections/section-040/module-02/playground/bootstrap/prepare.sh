#!/usr/bin/env bash
# Environment prep for the "Produce Compliance Reports From Policy Engines"
# playground (`ats-021-playground-040-02`).
#
# Environment preparation only — there is no task and no grading. This script:
#   1. installs Kyverno 1.19.1 and Gatekeeper 3.23.1 and waits for them,
#   2. applies the Starfleet workloads, two Kyverno ClusterPolicies in Audit
#      mode and one Gatekeeper template and Constraint in dryrun mode,
#   3. turns on API server audit logging on the control plane node with a
#      short Metadata-level policy.
set -euo pipefail

KYVERNO_VERSION="v1.19.1"
GATEKEEPER_VERSION="v3.23.1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[playground] Installing Kyverno ${KYVERNO_VERSION}..."
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

echo "[playground] Installing Gatekeeper ${GATEKEEPER_VERSION}..."
kubectl apply -f "https://raw.githubusercontent.com/open-policy-agent/gatekeeper/${GATEKEEPER_VERSION}/deploy/gatekeeper.yaml"
kubectl -n gatekeeper-system rollout status deployment/gatekeeper-controller-manager --timeout=300s
kubectl -n gatekeeper-system rollout status deployment/gatekeeper-audit --timeout=300s
kubectl wait --for=condition=Established crd/constrainttemplates.templates.gatekeeper.sh --timeout=120s

echo "[playground] Applying the Starfleet workloads..."
kubectl apply -f "$SCRIPT_DIR/../manifests/starfleet.yaml"
for d in scout probe shuttle legacy-beacon; do
  kubectl -n starfleet rollout status "deployment/$d" --timeout=180s
done
kubectl -n outpost rollout status deployment/drifter --timeout=180s

echo "[playground] Applying the Kyverno policies (Audit mode)..."
# The webhook can need a moment before it accepts policies.
for i in $(seq 1 30); do
  if kubectl apply -f "$SCRIPT_DIR/../manifests/kyverno-policies.yaml"; then
    break
  fi
  sleep 3
done

echo "[playground] Applying the Gatekeeper template and Constraint (dryrun)..."
kubectl apply -f "$SCRIPT_DIR/../manifests/gatekeeper-owner-label.yaml"
for i in $(seq 1 60); do
  if kubectl get crd k8srequiredlabels.constraints.gatekeeper.sh >/dev/null 2>&1; then
    break
  fi
  sleep 2
done
kubectl wait --for=condition=Established crd/k8srequiredlabels.constraints.gatekeeper.sh --timeout=120s
for i in $(seq 1 30); do
  if kubectl apply -f "$SCRIPT_DIR/../manifests/gatekeeper-owner-constraint.yaml"; then
    break
  fi
  sleep 3
done

echo "[playground] Turning on API server audit logging on the control plane node..."
if command -v podman >/dev/null 2>&1 && podman ps >/dev/null 2>&1; then
  RUNTIME=podman
else
  RUNTIME=docker
fi
NODE="$(kubectl get nodes -l node-role.kubernetes.io/control-plane -o jsonpath='{.items[0].metadata.name}')"

$RUNTIME exec "$NODE" mkdir -p /etc/kubernetes/audit /var/log/kubernetes/audit
$RUNTIME exec -i "$NODE" sh -c 'cat > /etc/kubernetes/audit/audit-policy.yaml' <<'POLICY'
apiVersion: audit.k8s.io/v1
kind: Policy
omitStages:
  - RequestReceived
rules:
  - level: None
    nonResourceURLs: ["/healthz*", "/livez*", "/readyz*", "/version"]
  - level: None
    users: ["system:kube-proxy"]
  - level: Metadata
POLICY

MANIFEST=/etc/kubernetes/manifests/kube-apiserver.yaml
$RUNTIME exec "$NODE" cp "$MANIFEST" /etc/kubernetes/kube-apiserver.before-audit.yaml
$RUNTIME exec "$NODE" cp "$MANIFEST" /tmp/kube-apiserver.yaml
$RUNTIME exec "$NODE" sed -i \
  -e '/^    - kube-apiserver$/a\    - --audit-policy-file=/etc/kubernetes/audit/audit-policy.yaml\n    - --audit-log-path=/var/log/kubernetes/audit/audit.log\n    - --audit-log-maxage=1\n    - --audit-log-maxbackup=1\n    - --audit-log-maxsize=10' \
  -e '/^    volumeMounts:$/a\    - mountPath: /etc/kubernetes/audit\n      name: audit-policy\n      readOnly: true\n    - mountPath: /var/log/kubernetes/audit\n      name: audit-log' \
  -e '/^  volumes:$/a\  - hostPath:\n      path: /etc/kubernetes/audit\n      type: Directory\n    name: audit-policy\n  - hostPath:\n      path: /var/log/kubernetes/audit\n      type: DirectoryOrCreate\n    name: audit-log' \
  /tmp/kube-apiserver.yaml
$RUNTIME exec "$NODE" mv /tmp/kube-apiserver.yaml "$MANIFEST"

echo "[playground] Waiting for the API server to restart with audit logging..."
sleep 20
for i in $(seq 1 60); do
  if kubectl --request-timeout=5s get --raw=/readyz >/dev/null 2>&1 \
     && kubectl --request-timeout=5s -n kube-system get pod "kube-apiserver-${NODE}" -o jsonpath='{.spec.containers[0].command}' 2>/dev/null | grep -q -- '--audit-log-path'; then
    break
  fi
  sleep 5
done
$RUNTIME exec "$NODE" test -s /var/log/kubernetes/audit/audit.log
$RUNTIME exec "$NODE" cp "$MANIFEST" /etc/kubernetes/kube-apiserver.audit-working.yaml
echo "[playground] Ready."
