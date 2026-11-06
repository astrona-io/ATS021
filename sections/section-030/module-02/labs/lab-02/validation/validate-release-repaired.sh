#!/usr/bin/env bash
# Check: the chart in ~/resources/probe carries version 0.2.0, lints and
# renders, and the release `probe` in starfleet is deployed from that exact
# chart (chart probe-0.2.0, manifest equal to the rendered chart).
set -uo pipefail
export PATH="$HOME/.astrona/bin:$PATH"

fail=0
CHART_DIR="$HOME/resources/probe"

if [ ! -f "$CHART_DIR/Chart.yaml" ]; then
  echo "FAIL: the chart directory $CHART_DIR has no Chart.yaml; keep the chart at ~/resources/probe"
  exit 1
fi

chart_version="$(helm show chart "$CHART_DIR" 2>/dev/null | awk '$1 == "version:" {print $2}')"
if [ "$chart_version" != "0.2.0" ]; then
  echo "FAIL: Chart.yaml in ~/resources/probe must have version 0.2.0, got ${chart_version:-none}"
  fail=1
fi

if ! helm lint "$CHART_DIR" >/dev/null 2>&1; then
  echo "FAIL: helm lint ~/resources/probe reports errors"
  fail=1
fi

local_manifest="$(helm template probe "$CHART_DIR" -n starfleet 2>/dev/null)"
if [ -z "$local_manifest" ]; then
  echo "FAIL: helm template probe ~/resources/probe -n starfleet renders nothing"
  fail=1
fi

release_json="$(helm list -n starfleet --filter '^probe$' -o json 2>/dev/null)"
release_chart="$(printf '%s' "$release_json" | jq -r '.[0].chart // empty')"
release_status="$(printf '%s' "$release_json" | jq -r '.[0].status // empty')"
if [ "$release_chart" != "probe-0.2.0" ]; then
  echo "FAIL: the release probe in starfleet must use chart probe-0.2.0, got ${release_chart:-none}"
  fail=1
fi
if [ "$release_status" != "deployed" ]; then
  echo "FAIL: the release probe in starfleet must have status deployed, got ${release_status:-none}; run helm history probe -n starfleet"
  fail=1
fi

release_manifest="$(helm get manifest probe -n starfleet 2>/dev/null)"
if [ -n "$local_manifest" ] && [ "$local_manifest" != "$release_manifest" ]; then
  echo "FAIL: the chart in ~/resources/probe renders differently from the installed release; make every change in the chart files and upgrade without --set or extra values files"
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: the release probe is deployed from chart probe-0.2.0 in ~/resources/probe"
fi
exit "$fail"
