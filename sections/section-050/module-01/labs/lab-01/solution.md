# Solution

Apply the configuration, then check both allowed and denied behavior.

Save this as `practice-solution.yaml`:

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
    script: "#!/bin/sh\nif [ \"$(cat /tekton/steps/step-validate/exitCode)\" = \"0\" ]; then\n  printf\
      \ pass | tee $(results.outcome.path)\nelse\n  printf fail | tee $(results.outcome.path)\nfi\n"
---
apiVersion: tekton.dev/v1
kind: Pipeline
metadata:
  name: release-gate
  namespace: pipelines
spec:
  workspaces:
  - name: release
  - name: policies
  tasks:
  - name: check
    taskRef:
      name: check-release
    workspaces:
    - name: release
      workspace: release
    - name: policies
      workspace: policies
  - name: deploy
    runAfter:
    - check
    when:
    - input: $(tasks.check.results.outcome)
      operator: in
      values:
      - pass
    taskRef:
      name: deploy-release
    workspaces:
    - name: release
      workspace: release
```

Apply it:

```sh
kubectl apply -f practice-solution.yaml
```

Check the result:

```sh
kubectl -n pipelines get pipelineruns
kubectl -n pipelines get taskruns -l tekton.dev/pipelineTask=deploy
kubectl -n pipelines get taskruns -l tekton.dev/pipelineTask=report
```

Use the returned objects and decisions to check every task. A denied request must identify the expected access or policy restriction; a connection failure is not evidence that the restriction works.


Save this as `pipelinerun-practice.yaml`. For each later run, choose a new name and change the release ConfigMap to the case being tested.

```yaml
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  name: practice-release
  namespace: pipelines
spec:
  pipelineRef:
    name: release-gate
  taskRunTemplate:
    serviceAccountName: pipeline-runner
  workspaces:
  - name: release
    configMap:
      name: release-compliant
  - name: policies
    configMap:
      name: platform-policies
```

Apply it:

```sh
kubectl apply -f pipelinerun-practice.yaml
```

Inspect the run:

```sh
kubectl -n pipelines get pipelinerun practice-release -o yaml
kubectl -n pipelines get taskruns -l tekton.dev/pipelineRun=practice-release
```
