#!/usr/bin/env bash
set -euo pipefail
kubectl wait --for=condition=Ready clusterpolicy/image-tags --timeout=180s
