#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
require_meshed_shuttle
expect_field namespace starfleet '{.metadata.annotations.config\.linkerd\.io/default-inbound-policy}' deny
expect_field services scout '{.spec.selector}' '{"app":"scout","version":"v1"}'
expect_field deployments shuttle '{.spec.template.spec.serviceAccountName}' shuttle
expect_field deployments caller '{.spec.template.spec.serviceAccountName}' probe
expect_field meshtlsauthentications.policy.linkerd.io shuttle '{.spec.identityRefs}' '[{"kind":"ServiceAccount","name":"shuttle"}]'
expect_field meshtlsauthentications.policy.linkerd.io shuttle '{.spec.identities}' ''
# Read both named policies so deleting the broken one cannot pass.
for version in v1 v2; do
  expect_field services "scout-$version" '{.spec.selector}' "{\"app\":\"scout\",\"version\":\"$version\"}"
  expect_field deployments "scout-$version" '{.spec.template.spec.serviceAccountName}' "scout-$version"
  policy="scout-$version-allow-shuttle"
  expect_field authorizationpolicies.policy.linkerd.io "$policy" '{.spec.targetRef}' "{\"group\":\"policy.linkerd.io\",\"kind\":\"Server\",\"name\":\"scout-$version-http\"}"
  expect_field authorizationpolicies.policy.linkerd.io "$policy" '{.spec.requiredAuthenticationRefs}' '[{"group":"policy.linkerd.io","kind":"MeshTLSAuthentication","name":"shuttle"}]'
  expect_code starfleet shuttle "http://scout-$version.starfleet/api/info" 200
  expect_code starfleet caller "http://scout-$version.starfleet/api/info" 403
  expect_code outpost drifter "http://scout-$version.starfleet/api/info" 403
done
echo 'PASS: authorization'
