# Read A Failed Task And Limit The Service Account

A Task can end in three ways that matter to a release: it succeeds, Tekton skips it, or it fails. The pipeline owner must tell these apart, because each one needs a different reaction. A failure also shows the last safety layer of the pipeline: the rights of the service account that runs the deploy step. This part makes a Task fail on purpose and reads why.

The deploy step runs `kubectl apply` inside a pod, and that pod uses the Kubernetes service account `pipeline-runner`. A **service account** is the identity a pod uses when it calls the Kubernetes API. Its rights come from a `Role` and a `RoleBinding`, as for any other API client. In the playground, the Role `release-deployer` in the `starfleet` namespace allows the verbs `get`, `list`, `create` and `patch` on Deployments, and the RoleBinding gives it to `pipeline-runner`. A **verb** is the action in an API request, such as `get` or `create`.

## Deploy a compliant release to the wrong namespace

The ConfigMap `release-outpost` holds a release that passes both policy rules but names the namespace `outpost` instead of `starfleet`. The check passes, so the gate opens. The API server then refuses the request, because `pipeline-runner` has no rights in `outpost`.

You can start a run without a YAML file, with `tkn pipeline start`. The flag `-w` binds a workspace, and `--showlog` follows the logs until the run ends:

<!-- astrona:playground:renew -->

```sh
tkn -n pipelines pipeline start release-gate --serviceaccount pipeline-runner -w name=release,config=release-outpost -w name=policies,config=platform-policies --showlog
```

You should see something like this. The Kyverno deprecation warning is left out:

```text
PipelineRun started: release-gate-run-ffgnk
Waiting for logs to be available...
[check : validate] 
[check : validate] Applying 2 policy rule(s) to 1 resource(s)...
[check : validate] 
[check : validate] pass: 2, fail: 0, warn: 0, error: 0, skip: 0 

[check : record-outcome] pass

task deploy has failed: "step-apply" exited with code 1: Error
[deploy : apply] Error from server (Forbidden): error when retrieving current configuration of:
[deploy : apply] Resource: "apps/v1, Resource=deployments", GroupVersionKind: "apps/v1, Kind=Deployment"
[deploy : apply] Name: "scout", Namespace: "outpost"
[deploy : apply] from server for: "/workspace/release/deployment.yaml": deployments.apps "scout" is forbidden: User "system:serviceaccount:pipelines:pipeline-runner" cannot get resource "deployments" in API group "apps" in the namespace "outpost"

failed to get logs for task deploy : container step-apply has failed  : [{"key":"StartedAt","value":"2026-11-02T19:17:11.302Z","type":3}]
[report : report] pipeline status: Failed
[report : report] check status:    Succeeded
```

The error message names the user, the verb, the resource and the namespace: `system:serviceaccount:pipelines:pipeline-runner` cannot `get` `deployments` in the namespace `outpost`. The `kubectl apply` command needs `get` first, to compare with the current object. The `failed to get logs` line comes from `tkn`, which cannot read the log of a container that exited with an error. The `report` Task still ran, and it printed `Failed`. Now read the run:

```sh
tkn -n pipelines pipelinerun describe --last | sed -n '/Status/,$p'
```

You should see something like:

```text
Status

STARTED          DURATION   STATUS
13 seconds ago   13s        Failed

Message

Tasks Completed: 3 (Failed: 1, Cancelled 0), Skipped: 0
TaskRun(s) cancelled: release-gate-run-ffgnk-deploy

Timeouts
 Pipeline:   1h0m0s

Workspaces

 NAME       SUB PATH   WORKSPACE BINDING
 release    ---        ConfigMap (config=release-outpost)
 policies   ---        ConfigMap (config=platform-policies)

Taskruns

 NAME                            TASK NAME   STARTED          DURATION   STATUS
 release-gate-run-ffgnk-report   report      4 seconds ago    4s         Succeeded
 release-gate-run-ffgnk-deploy   deploy      7 seconds ago    3s         Failed(StepFailed)
 release-gate-run-ffgnk-check    check       13 seconds ago   6s         Succeeded
```

The run is `Failed`, and `deploy` has a TaskRun with the status `Failed(StepFailed)`. The message also lists the deploy TaskRun under `TaskRun(s) cancelled`. Read the status column of the table for the cause: `Failed(StepFailed)`. Compare this with the blocked run: there, `deploy` had no TaskRun, `Skipped: 1` and the run `Succeeded`.

| End state | Cause | TaskRun exists | Run status |
| --- | --- | --- | --- |
| Succeeded | The Task ran and every step exited with `0` | yes | `Succeeded` |
| Skipped | A `when` expression was false | no | `Succeeded` or `Completed`, not failed |
| Failed | A step exited with an error | yes | `Failed` |

The pipeline owner reads a skipped Task as "the gate worked" and a failed Task as "something broke". Both leave the `scout` Deployment untouched, but only the second needs a repair.

## Ask what the service account may do

The failure shows one denied request. `kubectl auth can-i` asks the API server for the full answer on a verb and resource, and `--as` asks on behalf of another identity. Ask four questions:

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

The service account may create Deployments in `starfleet`. It may not create them in `outpost`, may not delete them and may not read Secrets. That is the least privilege the deploy step needs: the four verbs of `kubectl apply` on one resource in one namespace. A compromised or mistaken pipeline can change `scout` and nothing else. The check Task needs no Kubernetes API rights, because it reads only files from its workspaces.

## Common pitfalls

> [!WARNING]
> - Do not fix the failure above by binding `cluster-admin` to `pipeline-runner`. The pipeline would then deploy anywhere, and the compliance gate would be the only thing between a mistake and the whole cluster.
> - `kubectl apply` needs `get` and `create` (and `patch` for later updates). A Role with only `create` fails on the first `get`, as the error message shows.
> - A skipped deploy is a successful run. Alert on a failed run and report on a skipped one; do not treat them as the same event.
> - A ConfigMap workspace needs no rights from the service account. The kubelet mounts it, so a Role for ConfigMaps does not help and is not needed.
