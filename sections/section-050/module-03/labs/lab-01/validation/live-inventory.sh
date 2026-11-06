#!/usr/bin/env bash
# Sourced by graders. Compute inventory from live, ready Deployment images.
set -euo pipefail
export PATH="/usr/local/bin:$HOME/.local/bin:$PATH"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
NODE_ARCH=$(kubectl get nodes -o json | jq -er '.items[0].metadata.labels["kubernetes.io/arch"]')
for deployment in scout probe; do
  kubectl -n starfleet get deployment "$deployment" -o json > "$WORK/$deployment.deployment.json"
  jq -e '.spec.replicas == 1 and .status.availableReplicas >= 1 and
    .status.observedGeneration == .metadata.generation and
    (.spec.template.spec.containers | length) == 1' "$WORK/$deployment.deployment.json" >/dev/null
  image=$(jq -er '.spec.template.spec.containers[0].image' "$WORK/$deployment.deployment.json")
  case "$deployment" in
    scout) expected_image=docker.io/library/alpine@sha256:4b7ce07002c69e8f3d704a9c5d6fd3053be500b7f1c69fc0d80990c2ad8dd412 ;;
    probe) expected_image=docker.io/library/debian@sha256:a347fd7510ee31a84387619a492ad6c8eb0af2f2682b916ff3e643eb076f925a ;;
  esac
  [ "$image" = "$expected_image" ] || { echo 'FAIL: keep workload images unchanged'; exit 1; }
  jq -e --arg account "$deployment" '.spec.template.spec.serviceAccountName == $account' "$WORK/$deployment.deployment.json" >/dev/null
  # Remote-only avoids a dependency on a local container engine or its cache.
  trivy image --image-src remote --platform "linux/$NODE_ARCH" --format cyclonedx \
    --output "$WORK/$deployment.cdx.json" "$image" >/dev/null
  jq -e '.bomFormat == "CycloneDX" and (.components | length > 0)' "$WORK/$deployment.cdx.json" >/dev/null
done
