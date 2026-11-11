# Solution

Apply the configuration, then check both allowed and denied behavior.

Save this as `practice-solution.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: release-deployer
  namespace: starfleet
rules:
- apiGroups:
  - apps
  resources:
  - deployments
  verbs:
  - get
  - list
  - create
  - patch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pipeline-runner-release-deployer
  namespace: starfleet
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: release-deployer
subjects:
- kind: ServiceAccount
  name: pipeline-runner
  namespace: pipelines
```

Apply it:

```sh
kubectl apply -f practice-solution.yaml
```

Complete the change:

```sh
kubectl delete clusterrolebinding pipeline-runner-edit
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
