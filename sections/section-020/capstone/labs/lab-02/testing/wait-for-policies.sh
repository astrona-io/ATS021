#!/usr/bin/env bash
set -euo pipefail
LAB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$LAB_DIR/validation/lib.sh"
for version in v1 v2; do
  expect_code starfleet shuttle "http://scout-$version.starfleet/api/info" 200
  expect_code starfleet caller "http://scout-$version.starfleet/api/info" 403
done
