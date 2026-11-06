#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
kubectl apply -f "$SCRIPT_DIR/solution.yaml"
