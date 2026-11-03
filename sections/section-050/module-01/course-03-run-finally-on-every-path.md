# Run finally On Every Path

A gate that blocks a release must also leave a message that says what happened, and it must do so whether the run passed, was blocked or broke. A `finally` Task does that. This part runs the same pipeline on the compliant release and reads what `finally` received on the path where the deploy runs.

Tekton runs `finally` Tasks after all other Pipeline Tasks have finished, in parallel with each other. They run when the other Tasks succeeded, when one failed and when some were skipped. A `finally` Task cannot use `runAfter`, because Tekton already decides its place. The playground's `report` Task is the `finally` Task here. It receives two values through Tekton variables: `$(tasks.status)` is the overall state of the other Tasks, and `$(tasks.check.status)` is the state of the `check` Pipeline Task alone.

## Run the compliant release

The PipelineRun below is the same as before, except for its name and the ConfigMap bound to `release`. The `release-compliant` ConfigMap sets limits and uses the `6.15.0` image tag.

<!-- astrona:playground:renew -->

Save this as `pipelinerun-compliant.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  name: release-compliant-1
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
kubectl apply -f pipelinerun-compliant.yaml
```

Wait about 40 seconds. Then list the TaskRuns of the run. The `sed` command keeps only the table of TaskRuns:

```sh
tkn -n pipelines pipelinerun describe release-compliant-1 | sed -n '/Taskruns/,$p'
```

You should see something like:

```text
Taskruns

 NAME                         TASK NAME   STARTED          DURATION   STATUS
 release-compliant-1-report   report      52 seconds ago   6s         Succeeded
 release-compliant-1-deploy   deploy      58 seconds ago   6s         Succeeded
 release-compliant-1-check    check       1 minute ago     6s         Succeeded
```

All three Tasks ran, in the order `check`, `deploy`, `report`. The `deploy` Task ran because the check wrote `pass`. Read the logs of the whole run next. The `grep` command removes the Kyverno deprecation warning and the empty lines:

```sh
tkn -n pipelines pipelinerun logs release-compliant-1 | grep -vE "Warning|^$"
```

You should see:

```text
[check : validate] 
[check : validate] Applying 2 policy rule(s) to 1 resource(s)...
[check : validate] 
[check : validate] pass: 2, fail: 0, warn: 0, error: 0, skip: 0 
[check : record-outcome] pass
[deploy : apply] deployment.apps/scout created
[report : report] pipeline status: Succeeded
[report : report] check status:    Succeeded
```

The prefix of each line is now `[Pipeline Task : step]`. Both rules passed, the `deploy` Task created the `scout` Deployment, and `report` printed `Succeeded`. Check that the Deployment exists in the cluster:

```sh
kubectl -n starfleet get deploy,pods
```

You should see something like:

```text
NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/scout   1/1     1            1           52s

NAME                         READY   STATUS    RESTARTS   AGE
pod/scout-6557c68885-d898v   1/1     Running   0          52s
```

## What finally saw on each path

The `report` Task printed a different status on each run you made. The first run printed the status `Completed` for the pipeline, because the check passed and `deploy` was skipped. This run printed `Succeeded`, because every Task succeeded. The `check` Task succeeded both times, so a `finally` Task that only reads `$(tasks.check.status)` could not tell the two runs apart. The overall `$(tasks.status)` shows the difference.

| Run | `$(tasks.status)` | `$(tasks.check.status)` | `deploy` |
| --- | --- | --- | --- |
| Non-compliant release | `Completed` | `Succeeded` | skipped |
| Compliant release | `Succeeded` | `Succeeded` | succeeded |

The table lists the two runs of this module so far. You have seen `finally` on the success path and on the blocked path. A third path remains: a Task that fails.

## Common pitfalls

> [!WARNING]
> - A `finally` Task reports a state, not a decision. Put the decision in a result and a `when` expression, and use `finally` for reports and clean-up.
> - A `finally` Task runs even when the pipeline failed, so a `finally` Task that deploys or deletes things has to be written with that in mind.
> - A PipelineRun is a record of one run. Applying `pipelinerun-compliant.yaml` a second time changes nothing, because the run already exists. Use a new name, or `generateName` with `kubectl create`, for each run.
