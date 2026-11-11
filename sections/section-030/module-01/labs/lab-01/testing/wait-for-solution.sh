#!/usr/bin/env bash
set -euo pipefail
kubectl wait --for=condition=Ready clusterpolicy/require-limits --timeout=180s
