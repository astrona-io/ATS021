#!/usr/bin/env bash
# Starting state for the section 010 capstone. Environment only: the orbit
# namespace with the beacon workload, a ci-deployer service account bound to
# cluster-admin, and no Pod Security labels. The learner fixes all of it.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

kubectl apply -f "$DIR/manifests/lab-start.yaml"
kubectl -n orbit rollout status deployment/beacon --timeout=180s
echo "[lab] Ready."
