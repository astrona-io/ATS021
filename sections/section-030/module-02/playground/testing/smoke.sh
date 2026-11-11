#!/usr/bin/env bash
# Prove the chart's denied Pods recover after a template and values repair.
set -euo pipefail
export PATH="$HOME/.astrona/bin:$PATH"
dir=$(cd "$(dirname "$0")" && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cp -R "$dir/relay-chart" "$work/chart"
kubectl apply -f "$dir/required-labels.yaml"
for attempt in $(seq 1 60); do
  kubectl get crd k8srequiredlabels.constraints.gatekeeper.sh >/dev/null 2>&1 && break
  sleep 2
done
kubectl wait --for=condition=Established crd/k8srequiredlabels.constraints.gatekeeper.sh --timeout=60s
kubectl apply -f "$dir/require-team.yaml"
# Require the policy's own denial message, not a transport or webhook error.
for attempt in $(seq 1 60); do
  if output=$(kubectl -n starfleet run label-probe --image=ghcr.io/stefanprodan/podinfo:6.15.0 --dry-run=server 2>&1); then
    sleep 2
  elif [[ "$output" == *'[require-team-label]'* && "$output" == *'missing required label: team'* ]]; then
    break
  else
    echo "$output" >&2; exit 1
  fi
done
[[ "$output" == *'missing required label: team'* ]]
helm upgrade --install relay "$work/chart" -n starfleet
for attempt in $(seq 1 60); do
  events=$(kubectl -n starfleet get events --field-selector reason=FailedCreate -o json)
  if jq -e '.items[] | select(.involvedObject.kind=="ReplicaSet" and (.involvedObject.name|startswith("relay-"))) | select(.message|contains("[require-team-label]"))' <<<"$events" >/dev/null; then break; fi
  sleep 2
done
jq -e '.items[] | select(.involvedObject.kind=="ReplicaSet" and (.involvedObject.name|startswith("relay-"))) | select(.message|contains("[require-team-label]"))' <<<"$events" >/dev/null
python3 - "$work/chart" <<'FIX'
from pathlib import Path
import sys
chart=Path(sys.argv[1])
p=chart/'Chart.yaml';p.write_text(p.read_text().replace('version: 0.1.0','version: 0.2.0'))
p=chart/'values.yaml';p.write_text(p.read_text().replace('replicaCount: 1','replicaCount: 2'))
p=chart/'templates/deployment.yaml';p.write_text(p.read_text().replace('        app: relay','        app: relay\n        team: {{ .Values.team | quote }}'))
FIX
helm lint "$work/chart"
helm upgrade relay "$work/chart" -n starfleet
kubectl -n starfleet rollout status deployment/relay --timeout=120s
kubectl -n starfleet get deployment relay -o json | jq -e '.spec.replicas==2 and .status.availableReplicas==2 and .spec.template.metadata.labels.team=="starfleet"'
helm list -n starfleet -o json | jq -e '.[] | select(.name=="relay" and .chart=="relay-0.2.0" and .status=="deployed")'
echo 'PASS: Gatekeeper denied the chart Pods and the chart repair restored two available replicas'
