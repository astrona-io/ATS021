# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. The output below comes from the module that teaches this task; the exact names, times and suffixes differ in your cluster.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-050/module-01/labs/lab-01
```

Before you change anything, read the unfinished Pipeline and ask what `pipeline-runner` may do:

```sh
kubectl -n pipelines get pipeline release-gate -o yaml
kubectl auth can-i create deployments -n outpost --as=system:serviceaccount:pipelines:pipeline-runner
```

The Pipeline has the Pipeline Tasks `check` and `deploy`, and `deploy` has only `runAfter`. The second command prints `yes`, which is the fault of the fourth task. A submit now shows that all four checks fail.

## Step 1: Write the check Task

The Kyverno image has no shell, so the Task has two steps. The first step runs the check. With `onError: continue` Tekton does not stop the Task when this step exits with an error, and it writes the exit code of the step to the file `/tekton/steps/step-validate/exitCode`. The second step reads that file and writes `pass` or `fail` to the result `outcome`. Save this as `task-check-release.yaml`:

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

Run the Task once on the release that breaks the rules. Save this as `taskrun-check-bad.yaml`:

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

Create it with `kubectl create`, because the file uses `generateName`. Wait about 20 seconds, then read the result:

```sh
kubectl create -f taskrun-check-bad.yaml
kubectl -n pipelines get taskrun -o jsonpath='{.items[0].status.results}'
```

You should see:

```text
[{"name":"outcome","type":"string","value":"fail"}]
```

No check passes yet, because the Pipeline still deploys every release. Without `onError: continue` the result would stay empty.

## Step 2: Stop the deploy with a when expression

The `when` expression reads the result of `check`. If its condition is false, Tekton skips the Pipeline Task. The reference `$(tasks.check.results.outcome)` also tells Tekton that `deploy` depends on `check`. Save the Pipeline with the `when` expression on `deploy` as `pipeline-release-gate.yaml`:

```yaml
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
      runAfter: ["check"]
      when:
        - input: "$(tasks.check.results.outcome)"
          operator: in
          values: ["pass"]
      taskRef:
        name: deploy-release
      workspaces:
        - name: release
          workspace: release
```

Apply it:

```sh
kubectl apply -f pipeline-release-gate.yaml
```

Run the pipeline on the release that breaks the rules and read the run. Use the same PipelineRun as the module, with the workspace `release` bound to `release-noncompliant`:

```sh
tkn -n pipelines pipeline start release-gate --serviceaccount pipeline-runner -w name=release,config=release-noncompliant -w name=policies,config=platform-policies --showlog
tkn -n pipelines pipelinerun describe --last
kubectl -n starfleet get deploy
```

The `deploy` Pipeline Task has no TaskRun and appears under `Skipped Tasks`. The command `kubectl -n starfleet get deploy` shows that nothing reached the `starfleet` namespace. The run is listed as `Succeeded`, because a skipped Task is not a failure. Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-050/module-01/labs/lab-01 --keep
```

The checks `compliant-release-deployed` and `noncompliant-release-blocked` now pass.

## Step 3: Add the finally Task

A `finally` Task runs after all other Pipeline Tasks, whether they succeeded, failed or were skipped. The Task `report-outcome` already exists. Add a `finally` list at the same level as `tasks`. Save the complete Pipeline again as `pipeline-release-gate.yaml`. The file replaces the earlier one:

```yaml
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
      runAfter: ["check"]
      when:
        - input: "$(tasks.check.results.outcome)"
          operator: in
          values: ["pass"]
      taskRef:
        name: deploy-release
      workspaces:
        - name: release
          workspace: release
  finally:
    - name: report
      taskRef:
        name: report-outcome
      params:
        - name: pipeline-status
          value: "$(tasks.status)"
        - name: check-status
          value: "$(tasks.check.status)"
```

Apply it:

```sh
kubectl apply -f pipeline-release-gate.yaml
```

Run the compliant release and read the logs:

```sh
tkn -n pipelines pipeline start release-gate --serviceaccount pipeline-runner -w name=release,config=release-compliant -w name=policies,config=platform-policies --showlog
```

The log ends with the lines of the `report` Task, which print `pipeline status: Succeeded` and `check status:    Succeeded`. The `deploy` Task created the `scout` Deployment in `starfleet`. Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-050/module-01/labs/lab-01 --keep
```

The check `finally-runs-on-every-path` now passes.

## Step 4: Limit the service account

The ClusterRoleBinding `pipeline-runner-edit` gives the built-in ClusterRole `edit` to `pipeline-runner` in every namespace. Remove it and give the account only what `kubectl apply` needs for Deployments in `starfleet`: `get` to read the current object, `create` for a new one and `patch` for a later update. Save this as `role-release-deployer.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: release-deployer
  namespace: starfleet
rules:
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "create", "patch"]
```

Save this as `rolebinding-pipeline-runner-release-deployer.yaml`:

```yaml
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

Apply both files first, then delete the broad grant, so the pipeline never loses the rights it needs:

```sh
kubectl apply -f role-release-deployer.yaml -f rolebinding-pipeline-runner-release-deployer.yaml
kubectl delete clusterrolebinding pipeline-runner-edit
```

Ask the API server four questions:

```sh
kubectl auth can-i create deployments -n starfleet --as=system:serviceaccount:pipelines:pipeline-runner
kubectl auth can-i create deployments -n outpost --as=system:serviceaccount:pipelines:pipeline-runner
kubectl auth can-i delete deployments -n starfleet --as=system:serviceaccount:pipelines:pipeline-runner
kubectl auth can-i get secrets -n starfleet --as=system:serviceaccount:pipelines:pipeline-runner
```

You should see:

```text
yes
no
no
no
```

Do not bind `cluster-admin` to make a failed deploy work: the check for `outpost` fails then. Do not remove all rights either, because the deploy of a compliant release fails. Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-050/module-01/labs/lab-01
```

All four checks pass. Clean up:

```sh
astrona destroy ats-021-lab-050-01
```
