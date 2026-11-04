#!/usr/bin/env bash
set -euo pipefail
LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
kubectl apply -f "$LAB_DIR/solution/solution.yaml"
