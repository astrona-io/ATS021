#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
route=httproutes.gateway.networking.k8s.io
kubectl -n starfleet get "$route" scout-split >/dev/null 2>&1 || fail 'HTTPRoute scout-split must exist in starfleet'
# The parent is the core Service scout on port 80, not a Gateway.
parents="$(field "$route" scout-split '{range .spec.parentRefs[*]}{.group}{"|"}{.kind}{"|"}{.name}{"|"}{.namespace}{"|"}{.port}{"\n"}{end}')"
[ "$parents" = '|Service|scout||80' ] || [ "$parents" = '|Service|scout|starfleet|80' ] \
  || fail "scout-split must have one parentRef: group \"\", kind Service, name scout, port 80; got '${parents:-none}'"
rule_count="$(kubectl -n starfleet get "$route" scout-split -o 'go-template={{len .spec.rules}}')"
[ "$rule_count" = 1 ] || fail 'scout-split must have one rule'
backends="$(field "$route" scout-split '{range .spec.rules[0].backendRefs[*]}{.group}{"|"}{.kind}{"|"}{.name}{"|"}{.port}{"|"}{.weight}{"\n"}{end}' | sort)"
expected=$'|Service|scout-v1|80|75\n|Service|scout-v2|80|25'
[ "$backends" = "$expected" ] || fail 'scout-split must use backends scout-v1:80 weight 75 and scout-v2:80 weight 25'
namespaces="$(field "$route" scout-split '{.spec.rules[0].backendRefs[*].namespace}')"
[ -z "$namespaces" ] || [ "$namespaces" = starfleet ] || [ "$namespaces" = 'starfleet starfleet' ] \
  || fail 'Backends must stay in starfleet'
expect_field "$route" scout-split '{.spec.hostnames}{.spec.rules[0].filters}{.spec.rules[0].backendRefs[*].filters}' ''
matches="$(field "$route" scout-split '{.spec.rules[0].matches}')"
[ -z "$matches" ] || [ "$matches" = '[{"path":{"type":"PathPrefix","value":"/"}}]' ] || fail 'The rule must cover all paths'
# Linkerd's policy controller writes the parent status; wait for it.
status=""
for attempt in $(seq 1 10); do
  status="$(field "$route" scout-split '{range .status.parents[*]}{.controllerName}{"|"}{.parentRef.name}{"|"}{range .conditions[*]}{.type}{"="}{.status}{","}{end}{"\n"}{end}')"
  accepted="$(printf '%s\n' "$status" | grep '^linkerd.io/policy-controller|scout|' || true)"
  if [[ "$accepted" == *Accepted=True* && "$accepted" == *ResolvedRefs=True* ]]; then
    echo 'PASS: route-attached'
    exit 0
  fi
  sleep 3
done
fail "Linkerd must report Accepted=True and ResolvedRefs=True for parent scout; got '${status:-no status}'"
