#!/usr/bin/env bash
set -euo pipefail
kubectl wait --for=condition=Ready clusterpolicy/allowed-registries --timeout=180s
