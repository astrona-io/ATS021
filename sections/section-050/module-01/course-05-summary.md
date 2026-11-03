# Summary

A Tekton pipeline can stop a release before it reaches the cluster, and it can leave a record of why. The pieces are small: a Task that decides, a result that carries the decision, a condition that reads it, and a service account that limits the damage.

A Tekton Task is a list of steps that run as containers in one pod. A TaskRun runs a Task once. A Pipeline orders Tasks, and a PipelineRun runs a Pipeline once. Workspaces give the steps their files, and a workspace can come from a ConfigMap. Tekton replaces variables such as `$(workspaces.release.path)` before the pod starts.

A compliance check turns a policy decision into a Task result. The check step runs an image against the release file and the policy file. A step with `onError: continue` lets the Task go on after an error, and Tekton writes the exit code of that step to a file. A second step reads the exit code and writes `pass` or `fail` to the result. Any exit code other than `0` gives `fail`, so the gate fails closed.

A `when` expression reads a result and decides whether a Pipeline Task runs. With `$(tasks.check.results.outcome)` as input, the deploy runs only when the check wrote `pass`. The expression also makes the deploy depend on the check, and `runAfter` makes the order explicit. A Task that the expression rejects is skipped: it has no TaskRun, and the pipeline does not fail.

A `finally` Task runs after the other Tasks on every path. It can read `$(tasks.status)`, which was `Succeeded` when every Task ran, `Completed` when a Task was skipped and `Failed` when a Task failed. The three end states of a Task differ in what the reader must do. A succeeded Task needs nothing. A skipped Task means the gate worked. A failed Task means something broke, and the reason is in the logs of its TaskRun.

The service account of the PipelineRun limits what a pipeline can do when something goes wrong. The deploy step needed `get`, `list`, `create` and `patch` on Deployments in one namespace, and the API server refused everything else. `kubectl auth can-i --as` shows the rights of the service account without a run.

Key facts:

- `tkn pipelinerun describe` lists TaskRuns, skipped Tasks and the run status.
- `kubectl get pipelinerun -o jsonpath='{.status.skippedTasks}'` shows why a Task was skipped.
- `Failed(StepFailed)` on a TaskRun means a step exited with an error; `Skipped Tasks` means a `when` expression was false.
- `kubectl apply` needs `get` as well as `create` and `patch`.

<!-- astrona:playground:destroy -->
