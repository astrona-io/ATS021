#!/usr/bin/env bash
set -euo pipefail
kubectl wait --for=condition=Ready clusterpolicy/add-team-label --timeout=180s
