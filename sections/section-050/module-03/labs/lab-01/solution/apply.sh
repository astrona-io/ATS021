#!/usr/bin/env bash
# Reference solution: derive every answer, never pin package versions.
set -euo pipefail
export PATH="/usr/local/bin:$HOME/.local/bin:$PATH"
EVIDENCE_DIR=/tmp/ats021-050-03-audit
mkdir -p "$EVIDENCE_DIR"
NODE_ARCH=$(kubectl get nodes -o json | jq -er '.items[0].metadata.labels["kubernetes.io/arch"]')
for deployment in scout probe; do
  image=$(kubectl -n starfleet get deployment "$deployment" -o jsonpath='{.spec.template.spec.containers[0].image}')
  trivy image --image-src remote --platform "linux/$NODE_ARCH" --format cyclonedx \
    --output "$EVIDENCE_DIR/$deployment.cdx.json" "$image"
done
version=$(jq -er '.components[] | select(.name == "busybox") | .version' "$EVIDENCE_DIR/scout.cdx.json")
owners=$(for deployment in scout probe; do
  if jq -e 'any(.components[]; .name == "bash")' "$EVIDENCE_DIR/$deployment.cdx.json" >/dev/null; then echo "$deployment"; fi
done | sort | paste -sd, -)
kubectl -n starfleet create configmap sbom-audit \
  --from-literal="scout-busybox-version=$version" --from-literal="bash-deployments=$owners" \
  --dry-run=client -o yaml > "$EVIDENCE_DIR/configmap-sbom-audit.yaml"
kubectl apply -f "$EVIDENCE_DIR/configmap-sbom-audit.yaml"
