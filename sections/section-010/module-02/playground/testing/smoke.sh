#!/usr/bin/env bash
# Exercise the running-Pod inventory procedure from the namespace-level lesson.
set -euo pipefail
python3 "$(dirname "$0")/check-baseline-review.py"
