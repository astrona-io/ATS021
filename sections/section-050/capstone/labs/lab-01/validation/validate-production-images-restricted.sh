#!/usr/bin/env bash
# Check: starfleet-prod accepts only ghcr.io images that are pinned by digest.
set -uo pipefail

fail=0
exhausted=0
DIGEST="sha256:ec73780a8425f59ea49f5bc8cdff0d598805a224fbaa1f86c67a244f250fa9da"

# try_image <namespace> <image>: a server-side dry run of a Deployment, so every
# admission webhook runs and nothing is stored. Prints the combined output.
try_image() {
  kubectl -n "$1" create deployment grader-image-test --image="$2" --dry-run=server -o name 2>&1
}

# expect_rejected <namespace> <image> <why>
# Retries for about 45 seconds, because Kyverno needs a few seconds to register
# a policy change. After one request used up its retries, later ones try once.
expect_rejected() {
  local ns="$1" image="$2" why="$3" tries=15
  [ "$exhausted" -eq 1 ] && tries=1
  for _ in $(seq 1 "$tries"); do
    if ! try_image "$ns" "$image" >/dev/null; then
      return 0
    fi
    [ "$tries" -gt 1 ] && sleep 3
  done
  exhausted=1
  echo "FAIL: the image $image was accepted in $ns, but it must be rejected ($why)"
  fail=1
}

# expect_accepted <namespace> <image> <why>
expect_accepted() {
  local ns="$1" image="$2" why="$3" out=""
  for _ in $(seq 1 5); do
    if out="$(try_image "$ns" "$image")"; then
      return 0
    fi
    sleep 3
  done
  echo "FAIL: the image $image was rejected in $ns, but it must be accepted ($why): $(printf "%s" "$out" | tail -2)"
  fail=1
}

expect_rejected starfleet-prod docker.io/library/nginx:1.27.0 "registry not approved, tag only"
expect_rejected starfleet-prod "docker.io/library/nginx@$DIGEST" "registry not approved, even with a digest"
expect_rejected starfleet-prod "evil.example.com/ghcr.io/stefanprodan/podinfo@$DIGEST" "host only contains ghcr.io"
expect_rejected starfleet-prod ghcr.io/stefanprodan/podinfo:6.15.0 "approved registry but no digest"
expect_rejected starfleet-prod ghcr.io/stefanprodan/podinfo:latest "latest tag, no digest"
expect_accepted starfleet-prod "ghcr.io/stefanprodan/podinfo@$DIGEST" "approved registry and digest"
expect_accepted starfleet-prod "ghcr.io/stefanprodan/podinfo:6.15.0@$DIGEST" "approved registry, tag and digest"

if [ "$fail" -eq 0 ]; then
  echo "PASS: starfleet-prod accepts only ghcr.io images pinned by digest"
fi
exit "$fail"
