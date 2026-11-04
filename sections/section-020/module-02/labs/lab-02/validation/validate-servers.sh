#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
for version in v1 v2; do
  server="scout-$version-http"
  expect_field servers.policy.linkerd.io "$server" '{.spec.podSelector}' "{\"matchLabels\":{\"app\":\"scout\",\"version\":\"$version\"}}"
  expect_field servers.policy.linkerd.io "$server" '{.spec.port}' http
  expect_field servers.policy.linkerd.io "$server" '{.spec.proxyProtocol}' HTTP/1
  expect_field servers.policy.linkerd.io "$server" '{.spec.accessPolicy}' deny
done
echo 'PASS: servers'
