# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. The output below comes from the module that teaches this task; the exact names, times and suffixes differ in your cluster.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-050/capstone/labs/lab-01
```

Before you change anything, read the unfinished Pipeline, ask what `pipeline-runner` may do and try an image in production:

```sh
kubectl -n pipelines get pipeline release-gate -o yaml
kubectl auth can-i create deployments -n outpost --as=system:serviceaccount:pipelines:pipeline-runner
kubectl -n starfleet-prod create deployment image-test --image=nginx:latest --dry-run=server
```

The Pipeline has only the Pipeline Task `deploy` and only the workspace `release`. The second command prints `yes`, and the third command succeeds, because the policy `trusted-images` only records failures. A submit now shows that five checks fail. Only `other-namespaces-unaffected` passes, because nothing is restricted yet.

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

No check passes yet, because the Pipeline does not use the Task. Without `onError: continue` the result would stay empty.

## Step 2: Stop the deploy with a when expression

The Pipeline needs the new workspace `policies` and the Pipeline Task `check`. The `when` expression reads the result of `check`. If its condition is false, Tekton skips the Pipeline Task. The reference `$(tasks.check.results.outcome)` also tells Tekton that `deploy` depends on `check`. Save the Pipeline with the `when` expression on `deploy` as `pipeline-release-gate.yaml`:

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

Run the pipeline on the release that breaks the rules and read the run. Bind the workspace `release` to `release-noncompliant` and the workspace `policies` to `platform-policies`:

```sh
tkn -n pipelines pipeline start release-gate --serviceaccount pipeline-runner -w name=release,config=release-noncompliant -w name=policies,config=platform-policies --showlog
tkn -n pipelines pipelinerun describe --last
kubectl -n starfleet get deploy
```

The `deploy` Pipeline Task has no TaskRun and appears under `Skipped Tasks`. The command `kubectl -n starfleet get deploy` shows that nothing reached the `starfleet` namespace. The run is listed as `Succeeded`, because a skipped Task is not a failure. Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-050/capstone/labs/lab-01 --keep
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
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-050/capstone/labs/lab-01 --keep
```

The check `finally-runs-on-every-path` now passes.

## Step 4: Limit the service account

The two RoleBindings `pipeline-runner-edit` give the built-in ClusterRole `edit` to `pipeline-runner` in `starfleet` and in `outpost`. Remove both and give the account only what `kubectl apply` needs for Deployments in `starfleet`: `get` to read the current object, `create` for a new one and `patch` for a later update. Save this as `role-release-deployer.yaml`:

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

Apply both files first, then delete the broad grants, so the pipeline never loses the rights it needs:

```sh
kubectl apply -f role-release-deployer.yaml -f rolebinding-pipeline-runner-release-deployer.yaml
kubectl -n starfleet delete rolebinding pipeline-runner-edit
kubectl -n outpost delete rolebinding pipeline-runner-edit
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
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-050/capstone/labs/lab-01 --keep
```

The check `service-account-least-privilege` now passes.

## Step 5: Restrict images in production

The policy `trusted-images` has `failureAction: Audit` and one rule that covers every namespace with an `environment` label. Change it to `Enforce`, add a second rule that requires `@sha256:` in the image, and select only namespaces with the label `environment: production`. The pattern `ghcr.io/*` matches the start of the image string, so it also refuses `evil.example.com/ghcr.io/...`. Save the corrected policy as `clusterpolicy-trusted-images.yaml`:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: trusted-images
spec:
  background: true
  rules:
    - name: only-ghcr
      match:
        any:
          - resources:
              kinds:
                - Pod
              namespaceSelector:
                matchLabels:
                  environment: production
      validate:
        failureAction: Enforce
        message: "Images in production must come from ghcr.io."
        pattern:
          spec:
            containers:
              - image: "ghcr.io/*"
    - name: pin-by-digest
      match:
        any:
          - resources:
              kinds:
                - Pod
              namespaceSelector:
                matchLabels:
                  environment: production
      validate:
        failureAction: Enforce
        message: "Images in production must be pinned by digest (image@sha256:...)."
        pattern:
          spec:
            containers:
              - image: "*@sha256:*"
```

Apply it:

```sh
kubectl apply -f clusterpolicy-trusted-images.yaml
```

Kyverno prints a deprecation warning for the `kyverno.io/v1` kind. The old kind still works. Wait about ten seconds. Send three requests to `starfleet-prod` and two to the namespaces that must stay open:

```sh
kubectl -n starfleet-prod create deployment image-test --image=ghcr.io/stefanprodan/podinfo:6.15.0 --dry-run=server
kubectl -n starfleet-prod create deployment image-test --image=ghcr.io/stefanprodan/podinfo@sha256:ec73780a8425f59ea49f5bc8cdff0d598805a224fbaa1f86c67a244f250fa9da --dry-run=server
kubectl -n starfleet-prod create deployment image-test --image=nginx:latest --dry-run=server
kubectl -n starfleet create deployment image-test --image=ghcr.io/stefanprodan/podinfo:6.15.0 --dry-run=server
kubectl -n default create deployment image-test --image=nginx:latest --dry-run=server
```

The first and the third request are rejected by Kyverno. The second, the fourth and the fifth print `deployment.apps/image-test created (server dry run)`. Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-050/capstone/labs/lab-01
```

All six checks pass. Do not leave the policy in `Audit` mode, do not select every namespace and do not change the namespace labels. The grader rejects all three. Clean up:

```sh
astrona destroy ats-021-capstone-050
```
