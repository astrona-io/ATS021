#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
route=httproutes.gateway.networking.k8s.io
expect_field "$route" scout-split '{.spec.parentRefs}' '[{"group":"","kind":"Service","name":"scout","port":80}]'
rule_count="$(kubectl -n starfleet get "$route" scout-split -o 'go-template={{len .spec.rules}}')"
[ "$rule_count" = 1 ] || fail 'scout-split must have one rule'
backends="$(field "$route" scout-split '{range .spec.rules[0].backendRefs[*]}{.group}{"|"}{.kind}{"|"}{.name}{"|"}{.namespace}{"|"}{.port}{"|"}{.weight}{"\n"}{end}' | sort)"
expected=$'|Service|scout-v1||80|80\n|Service|scout-v2||80|20'
[ "$backends" = "$expected" ] || fail 'scout-split must use scout-v1:80 weight 80 and scout-v2:80 weight 20 in starfleet'
expect_field "$route" scout-split '{.spec.hostnames}{.spec.rules[0].filters}{.spec.rules[0].backendRefs[*].filters}' ''
matches="$(field "$route" scout-split '{.spec.rules[0].matches}')"
[ -z "$matches" ] || [ "$matches" = '[{"path":{"type":"PathPrefix","value":"/"}}]' ] || fail 'The rule must cover all paths'
echo 'PASS: route'
