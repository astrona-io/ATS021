#!/usr/bin/env bash
# Check: a Constraint of kind K8sDisallowedTags with enforcementAction dryrun
# lists the existing pod drifter in outpost in its audit results.
# The audit controller runs about once a minute, so the check waits up to 3 minutes.
set -uo pipefail

for _ in $(seq 1 36); do
  found="$(kubectl get k8sdisallowedtags -o json 2>/dev/null | jq -r '
    [.items[]
     | select(.spec.enforcementAction == "dryrun")
     | select(any(.status.violations[]?; .kind == "Pod" and .namespace == "outpost" and (.name | startswith("drifter"))))
     | .metadata.name] | first // empty')"
  if [ -n "$found" ]; then
    echo "PASS: constraint $found lists the drifter pod in its audit results"
    exit 0
  fi
  sleep 5
done

echo "FAIL: no K8sDisallowedTags constraint with enforcementAction dryrun lists the drifter pod in outpost"
exit 1
