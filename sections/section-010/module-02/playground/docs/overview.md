# Overview: Restrict Pods With Pod Security Admission (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with the example workloads and one dangerous Deployment, and then waits. There is no task, no `astrona submit` and no pass or fail. Change namespace labels, fix pod specs, break them, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it, as the cluster administrator. Pod Security Admission is built in; there is no policy engine.

  | Namespace | What is in it |
  | --- | --- |
  | `starfleet` | No Pod Security labels. `scout` (`podinfo`, image user `app` with ID `100`), `probe` and `shuttle` run with no `securityContext`. `privileged-debug` runs a privileged container with the node's root file system at `/host`, on purpose |
  | `outpost` | Labelled `pod-security.kubernetes.io/enforce: baseline`. The `drifter` client runs here |

## Helpers

Paste these once in each new terminal. `psa_test` runs a server-side dry run of an `enforce` level on a namespace and prints the pods that would break it. `psa_labels` prints a namespace's Pod Security labels. `failed_creates` lists the `FailedCreate` events in a namespace.

```sh
psa_test() {
  kubectl label --dry-run=server --overwrite namespace "$1" "pod-security.kubernetes.io/enforce=$2"
}
psa_labels() {
  kubectl get namespace "$1" -o jsonpath='{.metadata.labels}' | tr ',' '\n' | grep pod-security
}
failed_creates() {
  kubectl -n "$1" get events --field-selector reason=FailedCreate
}
```

Use them like this: `psa_test starfleet restricted`, `psa_labels outpost`, `failed_creates starfleet`.

## Practice tasks

- Before you change anything, predict which pods `psa_test starfleet baseline` lists and which checks each one fails. Then run it.
- Label `starfleet` to warn at `restricted`, then create a Deployment that breaks it. Note whether the warning appears on the Deployment, on the pods, or both.
- Enforce `baseline` on `starfleet` and delete the running `privileged-debug` pod. Find out where the Deployment controller reports the problem.
- Give `probe` and `shuttle` a `securityContext` that passes `restricted`. Check each image's user with `kubectl exec ... -- id` first.
- Try to create a pod in `outpost` with `hostNetwork: true`, then with `runAsUser: 0`. Read which level each one breaks.
