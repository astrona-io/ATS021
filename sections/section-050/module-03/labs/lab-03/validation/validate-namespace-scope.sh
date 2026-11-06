#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/admission-helpers.sh"
# A missing policy must not earn points just because both images are allowed.
require_policy
check_labels
for namespace in outpost outpost-unlabelled; do
  expect_allowed "$namespace" "$SIGNED_IMAGE"
  expect_allowed "$namespace" "$UNSIGNED_IMAGE"
done
echo 'PASS: namespace-scope'
