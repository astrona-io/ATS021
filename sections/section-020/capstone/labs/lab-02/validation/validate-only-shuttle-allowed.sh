#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
policy=authorizationpolicies.policy.linkerd.io
authentication=meshtlsauthentications.policy.linkerd.io
# Both callers must be in the mesh, or the proxy cannot see an identity to allow or deny.
require_meshed shuttle
require_meshed caller
# The identities must still be the real ones: the fix is in the policy, not in the callers.
expect_field deployment shuttle '{.spec.template.spec.serviceAccountName}' shuttle
expect_field deployment caller '{.spec.template.spec.serviceAccountName}' probe
# Exactly one AuthorizationPolicy, the one the task names, and it targets the Server.
policy_names="$(kubectl -n starfleet get "$policy" -o 'jsonpath={.items[*].metadata.name}')"
[ "$policy_names" = scout-allow-shuttle ] || fail "starfleet must hold exactly one AuthorizationPolicy, scout-allow-shuttle; got '${policy_names:-none}'"
expect_field "$policy" scout-allow-shuttle '{.spec.targetRef}' '{"group":"policy.linkerd.io","kind":"Server","name":"scout-http"}'
auth_refs="$(field "$policy" scout-allow-shuttle '{range .spec.requiredAuthenticationRefs[*]}{.group}{"|"}{.kind}{"|"}{.name}{"\n"}{end}')"
[ "$auth_refs" = 'policy.linkerd.io|MeshTLSAuthentication|scout-callers' ] \
  || fail 'scout-allow-shuttle must require exactly one authentication, MeshTLSAuthentication scout-callers'
# The repaired authentication names shuttle by ServiceAccount, nothing else.
identity_refs="$(field "$authentication" scout-callers '{range .spec.identityRefs[*]}{.kind}{"|"}{.name}{"|"}{.namespace}{"\n"}{end}')"
[ "$identity_refs" = 'ServiceAccount|shuttle|' ] || [ "$identity_refs" = 'ServiceAccount|shuttle|starfleet' ] \
  || fail "scout-callers must reference exactly the ServiceAccount shuttle; got '${identity_refs:-none}'"
expect_field "$authentication" scout-callers '{.spec.identities}' ''
# Real requests decide: shuttle in, caller out, on both versions.
expect_code starfleet shuttle http://scout-v1.starfleet/api/info 200
expect_code starfleet shuttle http://scout-v2.starfleet/api/info 200
expect_code starfleet caller http://scout-v1.starfleet/api/info 403
expect_code starfleet caller http://scout-v2.starfleet/api/info 403
echo 'PASS: only-shuttle-allowed'
