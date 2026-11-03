# Run A Compliance Check As A Tekton Task

A release pipeline must stop a release that breaks the platform's rules before it reaches the cluster. The cluster's admission controllers also reject such a release, but only after the pipeline has tried to deploy it. A check in the pipeline gives feedback earlier and leaves a record of why the release stopped. This part builds that check as a Tekton `Task` and runs it once on its own.

Tekton Pipelines is a Kubernetes add-on that runs build and delivery work as Kubernetes objects. A **Task** is a list of **steps**. Tekton runs all steps of one Task in one pod, one container per step, in order. A **TaskRun** is one execution of a Task. Your playground has Tekton Pipelines 1.17.0 installed and a Task called `deploy-release` in the `pipelines` namespace. That Task applies a Deployment file with `kubectl`.

## What the check must do

The platform keeps its rules in a policy file, and a release is a Deployment file. The check compares the second against the first. The playground has both in ConfigMaps in the `pipelines` namespace: `platform-policies` holds `policies.yaml`, and each release ConfigMap holds a `deployment.yaml`. Tekton passes files to a Task through **workspaces**. A workspace is a directory that Tekton mounts into every step, and it can come from a ConfigMap.

The check step runs the Kyverno command line image `ghcr.io/kyverno/kyverno-cli:v1.19.1` with `apply`. That command reads policies and resources from files and prints which rules the resource breaks. You use it as one step image. The Tekton parts are the subject here.

The Kyverno image has no shell, so a script cannot sit in the same step. The Task therefore has two steps. The first step runs the check. The second step reads the exit code of the first and writes the outcome to a **Task result**, which is a small value that a Task writes to a file so that later Tasks can read it.

Two Tekton details make this work. A step with `onError: continue` does not stop the Task when it exits with an error. Tekton then writes the exit code of that step to the file `/tekton/steps/step-<name>/exitCode`.

<!-- astrona:playground:renew -->

Save this as `task-check-release.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: check-release
  namespace: pipelines
spec:
  description: Checks the release against the platform policies and writes pass or fail to a result.
  workspaces:
    - name: release
      readOnly: true
    - name: policies
      readOnly: true
  results:
    - name: outcome
      description: pass if the release follows every policy, fail if not
  steps:
    - name: validate
      image: ghcr.io/kyverno/kyverno-cli:v1.19.1
      onError: continue
      args:
        - apply
        - $(workspaces.policies.path)/policies.yaml
        - --resource
        - $(workspaces.release.path)/deployment.yaml
    - name: record-outcome
      image: curlimages/curl:8.22.0
      script: |
        #!/bin/sh
        if [ "$(cat /tekton/steps/step-validate/exitCode)" = "0" ]; then
          printf pass | tee $(results.outcome.path)
        else
          printf fail | tee $(results.outcome.path)
        fi
```

Apply it:

```sh
kubectl apply -f task-check-release.yaml
```

The strings such as `$(workspaces.policies.path)` are Tekton variables. The Tekton controller replaces them with real paths before it creates the pod. The `record-outcome` step writes to `$(results.outcome.path)`, the file that Tekton reads as the result called `outcome`.

## Run the Task on a release that breaks the rules

A TaskRun connects the Task's workspaces to real data. This TaskRun uses the `release-noncompliant` release, which has no resource limits and uses the `latest` image tag. The file uses `generateName`, so the API server adds a random suffix to the name and you can create the run again.

Save this as `taskrun-check-bad.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  generateName: check-bad-
  namespace: pipelines
spec:
  taskRef:
    name: check-release
  workspaces:
    - name: release
      configMap:
        name: release-noncompliant
    - name: policies
      configMap:
        name: platform-policies
```

Create it. This file uses `generateName`, so use `kubectl create` and not `kubectl apply`:

```sh
kubectl create -f taskrun-check-bad.yaml
```

You should see something like:

```text
taskrun.tekton.dev/check-bad-nxddb created
```

The suffix differs in your cluster. Wait about 20 seconds for the pod to start and finish, then read the logs of the latest TaskRun with `tkn`, the Tekton command line tool:

```sh
tkn -n pipelines taskrun logs --last
```

You should see something like:

```text
[validate] Warning: /workspace/policies/policies.yaml: kyverno.io/v1 ClusterPolicy is deprecated and will be removed in a future release; migrate to ValidatingPolicy, MutatingPolicy, GeneratingPolicy or ImageValidatingPolicy (policies.kyverno.io), see https://kyverno.io/docs/guides/migration-to-cel/
[validate] 
[validate] Applying 2 policy rule(s) to 1 resource(s)...
[validate] policy release-rules -> resource starfleet/Deployment/scout failed:
[validate] 1 - require-cpu-memory-limits validation error: Every container must set resources.limits.cpu and resources.limits.memory. rule require-cpu-memory-limits failed at path /spec/template/spec/containers/0/resources/
[validate] 2 - disallow-latest-tag validation error: Images must use a fixed tag, not latest. rule disallow-latest-tag failed at path /spec/template/spec/containers/0/image/
[validate] 
[validate] pass: 0, fail: 2, warn: 0, error: 0, skip: 0 

[record-outcome] fail
```

Each log line starts with the name of the step that wrote it. The `validate` step reports both broken rules and exits with an error, and Tekton continues because of `onError: continue`. The `record-outcome` step then prints `fail`. The warning comes from Kyverno 1.19.1 and does not change the result.

Read the result from the TaskRun object. Only one TaskRun exists so far, so the first item in the list is the one you created:

```sh
kubectl -n pipelines get taskrun -o jsonpath='{.items[0].status.results}'
```

You should see:

```text
[{"name":"outcome","type":"string","value":"fail"}]
```

The Task now turns a policy decision into one word that later Tasks can read. The next question is how a Pipeline uses that word to decide whether to deploy.

## Common pitfalls

> [!WARNING]
> - Without `onError: continue`, a failing `validate` step fails the whole Task, the second step never runs, and the Task writes no result.
> - The `record-outcome` step treats every non-zero exit code of `validate` as `fail`. A broken policy file and a broken release both give `fail`, so the pipeline stops in both cases.
> - A workspace that comes from a ConfigMap is read-only. A step cannot write into it.
> - Create a TaskRun that uses `generateName` with `kubectl create`. `kubectl apply` needs a fixed name.
