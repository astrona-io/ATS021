#!/usr/bin/env bash
# Check: beacon no longer uses the latest tag, the template and a deny
# constraint still exist, and the Gatekeeper audit reports no violation.
set -uo pipefail

fail=0

image="$(kubectl -n starfleet get deployment beacon -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)"
if [ -z "$image" ]; then
  echo "FAIL: deployment beacon not found in starfleet (do not delete it)"
  fail=1
else
  tag=""
  case "$image" in
    *:*) tag="${image##*:}" ;;
  esac
  if [ -z "$tag" ] || [ "$tag" = "latest" ]; then
    echo "FAIL: beacon uses the image $image, which has no pinned tag"
    fail=1
  fi
fi

if ! kubectl get constrainttemplate k8sdisallowedtags >/dev/null 2>&1; then
  echo "FAIL: the ConstraintTemplate k8sdisallowedtags was deleted"
  fail=1
fi

# At least one K8sDisallowedTags constraint must deny. Deny is the default.
denying="$(kubectl get k8sdisallowedtags -o jsonpath='{range .items[*]}{.metadata.name}{"="}{.spec.enforcementAction}{"\n"}{end}' 2>/dev/null | awk -F= '$2=="deny" || $2=="" {print $1}')"
if [ -z "$denying" ]; then
  echo "FAIL: no K8sDisallowedTags constraint with enforcementAction deny exists"
  fail=1
fi

# Wait for an audit run that sees the fixed beacon (the audit runs about once a
# minute). Every denying constraint must report 0 violations.
if [ "$fail" -eq 0 ]; then
  clean=0
  last=""
  for _ in $(seq 1 24); do
    last=""
    clean=1
    for name in $denying; do
      total="$(kubectl get k8sdisallowedtags "$name" -o jsonpath='{.status.totalViolations}' 2>/dev/null)"
      last="$last $name=${total:-pending}"
      if [ "$total" != "0" ]; then
        clean=0
      fi
    done
    [ "$clean" -eq 1 ] && break
    sleep 10
  done
  if [ "$clean" -ne 1 ]; then
    echo "FAIL: the Gatekeeper audit still reports violations or has not run:$last"
    fail=1
  fi
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: beacon is pinned and the Gatekeeper audit finds no violation"
fi
exit "$fail"
