#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_meshed_shuttle
# A route object alone is insufficient: classify replies using live pod names.
backend_v1="$(kubectl -n starfleet get pods -l app=scout,version=v1 -o 'jsonpath={.items[0].metadata.name}')"
backend_v2="$(kubectl -n starfleet get pods -l app=scout,version=v2 -o 'jsonpath={.items[0].metadata.name}')"
[ -n "$backend_v1" ] && [ -n "$backend_v2" ] || fail 'Both backend pods must exist'
expect_code starfleet shuttle http://scout-v1.starfleet/api/info 200
expect_code starfleet shuttle http://scout-v2.starfleet/api/info 200
# Warm up the parent Service after the control plane has sent its configuration.
expect_code starfleet shuttle http://scout.starfleet/api/info 200
counts="$(kubectl -n starfleet exec deploy/shuttle -c shuttle -- sh -c '
  backend_v1="$1"; backend_v2="$2"
  count_v1=0; count_v2=0; request=0
  while [ "$request" -lt 400 ]; do
    body=$(curl -fsS --max-time 5 http://scout.starfleet/api/info) || exit 1
    case "$body" in
      *\""$backend_v1"\"*) count_v1=$((count_v1 + 1)) ;;
      *\""$backend_v2"\"*) count_v2=$((count_v2 + 1)) ;;
      *) echo "Unexpected backend response" >&2; exit 1 ;;
    esac
    request=$((request + 1))
  done
  printf "%s %s\n" "$count_v1" "$count_v2"
' sh "$backend_v1" "$backend_v2")" || fail 'All 400 requests must succeed and identify a live backend'
read -r count_v1 count_v2 <<< "$counts"
[[ "$count_v1" =~ ^[0-9]+$ && "$count_v2" =~ ^[0-9]+$ ]] || fail 'Invalid request counts'
[ "$((count_v1 + count_v2))" -eq 400 ] || fail 'Expected 400 replies'
[ "$count_v2" -ge 40 ] && [ "$count_v2" -le 120 ] || fail "Expected 10–30% v2 over 400 requests; got $count_v2 v2 replies"
echo "PASS: observed-split (v1=$count_v1 v2=$count_v2)"
