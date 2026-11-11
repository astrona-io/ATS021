#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
kubectl apply -f "$DIR/solution.yaml"
kubectl delete clusterrolebinding pipeline-runner-edit
