#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
server=servers.policy.linkerd.io
kubectl -n starfleet get "$server" scout-http >/dev/null 2>&1 || fail 'Server scout-http must exist in starfleet'
# One Server covers both versions: select on app=scout only.
expect_field "$server" scout-http '{.spec.podSelector.matchLabels}' '{"app":"scout"}'
expect_field "$server" scout-http '{.spec.podSelector.matchExpressions}' ''
port="$(field "$server" scout-http '{.spec.port}')"
[ "$port" = http ] || [ "$port" = 9898 ] || fail "scout-http must select the pod port http (9898); got '${port:-none}'"
expect_field "$server" scout-http '{.spec.proxyProtocol}' 'HTTP/1'
access_policy="$(field "$server" scout-http '{.spec.accessPolicy}')"
[ -z "$access_policy" ] || [ "$access_policy" = deny ] || fail "scout-http accessPolicy must be deny; got $access_policy"
server_count="$(kubectl -n starfleet get "$server" -o 'jsonpath={.items[*].metadata.name}' | wc -w | tr -d ' ')"
[ "$server_count" = 1 ] || fail 'starfleet must hold exactly one Server, scout-http'
echo 'PASS: server-protects-scout'
