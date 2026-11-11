#!/usr/bin/env bash
# Check: a compliant release is checked, deployed to starfleet and reports outcome pass. The grader brings its own policy file and release.
set -uo pipefail

fail=0
NS=pipelines
RUNS=()
RUN=""
RUN_STATUS=""

cleanup() {
  for r in "${RUNS[@]:-}"; do
    [ -n "$r" ] && kubectl -n "$NS" delete pipelinerun "$r" --ignore-not-found --wait=false >/dev/null 2>&1
  done
  kubectl -n "$NS" delete configmap grader-policies grader-release-ok grader-release-nolimits grader-release-latest grader-release-invalid grader-release-outpost --ignore-not-found >/dev/null 2>&1
  kubectl -n starfleet delete deployment grader-ok grader-nolimits grader-latest grader-invalid --ignore-not-found >/dev/null 2>&1
  kubectl -n outpost delete deployment grader-outpost --ignore-not-found >/dev/null 2>&1
}
trap cleanup EXIT

# release_cm <configmap> <deployment> <namespace> <image> <limits: yes|no> [replicas]
# Prints a ConfigMap whose file deployment.yaml holds one Deployment.
release_cm() {
  local cm="$1" dep="$2" ns="$3" image="$4" limits="$5" replicas="${6:-1}"
  cat <<YAML
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: $cm
  namespace: pipelines
data:
  deployment.yaml: |
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: $dep
      namespace: $ns
      labels:
        app: $dep
    spec:
      replicas: $replicas
      selector:
        matchLabels:
          app: $dep
      template:
        metadata:
          labels:
            app: $dep
        spec:
          containers:
            - name: app
              image: $image
YAML
  if [ "$limits" = "yes" ]; then
    cat <<YAML
              resources:
                limits:
                  cpu: 100m
                  memory: 64Mi
YAML
  fi
}

# The grader brings its own policy file and releases, so changing the lab's
# ConfigMaps cannot change the result.
setup_fixtures() {
  {
    cat <<'YAML'
apiVersion: v1
kind: ConfigMap
metadata:
  name: grader-policies
  namespace: pipelines
data:
  policies.yaml: |
    apiVersion: kyverno.io/v1
    kind: ClusterPolicy
    metadata:
      name: release-rules
    spec:
      rules:
        - name: require-cpu-memory-limits
          match:
            any:
              - resources:
                  kinds: ["Deployment"]
          validate:
            failureAction: Enforce
            message: "Every container must set resources.limits.cpu and resources.limits.memory."
            pattern:
              spec:
                template:
                  spec:
                    containers:
                      - resources:
                          limits:
                            cpu: "?*"
                            memory: "?*"
        - name: disallow-latest-tag
          match:
            any:
              - resources:
                  kinds: ["Deployment"]
          validate:
            failureAction: Enforce
            message: "Images must use a fixed tag, not latest."
            pattern:
              spec:
                template:
                  spec:
                    containers:
                      - image: "!*:latest"
YAML
    release_cm grader-release-ok grader-ok starfleet ghcr.io/stefanprodan/podinfo:6.15.0 yes
    release_cm grader-release-nolimits grader-nolimits starfleet ghcr.io/stefanprodan/podinfo:6.15.0 no
    release_cm grader-release-latest grader-latest starfleet ghcr.io/stefanprodan/podinfo:latest yes
    release_cm grader-release-invalid grader-invalid starfleet ghcr.io/stefanprodan/podinfo:6.15.0 yes -1
    release_cm grader-release-outpost grader-outpost outpost ghcr.io/stefanprodan/podinfo:6.15.0 yes
  } | kubectl apply -f - >/dev/null
}

# run_release <release configmap>
# Starts the Pipeline release-gate with the service account pipeline-runner and
# waits up to 5 minutes. Sets RUN (the PipelineRun name) and RUN_STATUS
# (True = succeeded, False = failed).
run_release() {
  local cm="$1"
  if ! RUN="$(kubectl create -o jsonpath='{.metadata.name}' -f - <<YAML
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: grader-run-
  namespace: pipelines
spec:
  pipelineRef:
    name: release-gate
  taskRunTemplate:
    serviceAccountName: pipeline-runner
  workspaces:
    - name: release
      configMap:
        name: $cm
    - name: policies
      configMap:
        name: grader-policies
YAML
  )"; then
    echo "FAIL: could not start the Pipeline release-gate: $RUN"
    RUN=""
    return 1
  fi
  RUNS+=("$RUN")
  for _ in $(seq 1 100); do
    RUN_STATUS="$(kubectl -n "$NS" get pipelinerun "$RUN" -o jsonpath='{.status.conditions[0].status}' 2>/dev/null)"
    case "$RUN_STATUS" in
      True | False) return 0 ;;
    esac
    sleep 3
  done
  echo "FAIL: the PipelineRun $RUN did not finish within 5 minutes"
  return 1
}

run_message() {
  kubectl -n "$NS" get pipelinerun "$1" -o jsonpath='{.status.conditions[0].reason}: {.status.conditions[0].message}' 2>/dev/null
}

# task_state <run> <pipeline task>: True, False, Unknown, or none when no TaskRun exists.
task_state() {
  local s
  s="$(kubectl -n "$NS" get taskrun -l "tekton.dev/pipelineRun=$1,tekton.dev/pipelineTask=$2" -o jsonpath='{.items[0].status.conditions[0].status}' 2>/dev/null)"
  echo "${s:-none}"
}

# task_result <run> <pipeline task> <result name>
task_result() {
  kubectl -n "$NS" get taskrun -l "tekton.dev/pipelineRun=$1,tekton.dev/pipelineTask=$2" -o jsonpath="{.items[0].status.results[?(@.name==\"$3\")].value}" 2>/dev/null
}

skipped_tasks() {
  kubectl -n "$NS" get pipelinerun "$1" -o jsonpath='{.status.skippedTasks[*].name}' 2>/dev/null
}

finally_name() {
  kubectl -n "$NS" get pipeline release-gate -o jsonpath='{.spec.finally[0].name}' 2>/dev/null
}

deployment_image() {
  kubectl -n "$1" get deployment "$2" -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null
}

if ! kubectl -n "$NS" get pipeline release-gate >/dev/null 2>&1; then
  echo "FAIL: the Pipeline release-gate does not exist in the namespace pipelines"
  exit 1
fi
setup_fixtures || { echo "FAIL: the grader could not create its fixtures"; exit 1; }

# Check: a compliant release passes the check, the deploy runs and the Deployment exists.
kubectl -n starfleet delete deployment grader-ok --ignore-not-found --wait=true >/dev/null 2>&1

if run_release grader-release-ok; then
  if [ "$RUN_STATUS" != "True" ]; then
    echo "FAIL: the PipelineRun for a compliant release did not succeed ($(run_message "$RUN"))"
    fail=1
  fi
  got="$(task_result "$RUN" check outcome)"
  [ "$got" = "pass" ] || { echo "FAIL: the Pipeline Task check wrote the result outcome='$got' for a compliant release, expected pass"; fail=1; }
  [ "$(task_state "$RUN" deploy)" = "True" ] || { echo "FAIL: the Pipeline Task deploy did not succeed for a compliant release"; fail=1; }
  image="$(deployment_image starfleet grader-ok)"
  [ "$image" = "ghcr.io/stefanprodan/podinfo:6.15.0" ] || { echo "FAIL: the compliant release was not deployed to starfleet (image found: '${image:-none}')"; fail=1; }
else
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: a compliant release is checked, deployed to starfleet and the result is pass"
fi
exit "$fail"
