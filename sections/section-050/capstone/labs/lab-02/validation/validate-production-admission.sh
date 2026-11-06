#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/admission-helpers.sh"
require_policy
check_labels
for namespace in starfleet-prod starfleet-canary; do
  expect_allowed "$namespace" "$SIGNED_IMAGE"
  expect_denied "$namespace" "$UNSIGNED_IMAGE"
done
echo 'PASS: production-admission'
