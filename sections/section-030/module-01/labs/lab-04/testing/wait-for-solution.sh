#!/usr/bin/env bash
set -euo pipefail
kubectl wait --for=condition=Ready clusterpolicy/default-deny-networkpolicy --timeout=180s
