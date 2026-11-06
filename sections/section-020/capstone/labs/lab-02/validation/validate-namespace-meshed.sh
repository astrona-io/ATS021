#!/usr/bin/env bash
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
# The namespace annotation makes new pods get a proxy; existing pods must be restarted.
inject="$(kubectl get namespace starfleet -o 'jsonpath={.metadata.annotations.linkerd\.io/inject}')"
[ "$inject" = enabled ] || fail "Namespace starfleet must carry linkerd.io/inject=enabled; got '${inject:-none}'"
for name in scout-v1 scout-v2 shuttle caller; do
  kubectl -n starfleet rollout status "deployment/$name" --timeout=120s >/dev/null 2>&1 \
    || fail "Deployment $name must finish its rollout"
done
for app in scout shuttle caller; do
  require_meshed "$app"
done
echo 'PASS: namespace-meshed'
