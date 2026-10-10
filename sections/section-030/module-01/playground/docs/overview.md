# Overview: Validate, Mutate And Generate With Kyverno (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with Kyverno and the example workloads, and then waits. There is no task, no `astrona submit` and no pass or fail. Write policies, break workloads, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it.
- **Kyverno 1.19.1** with its admission, background, reports and cleanup controllers, and its webhooks ready. Applying a `kyverno.io/v1` ClusterPolicy prints a deprecation warning; the policy still works. PolicyExceptions are switched off, as in a default installation.

  | Namespace | Workloads | Deliberate gaps |
  | --- | --- | --- |
  | `starfleet` | `scout`, `probe`, `shuttle` | `probe` has no resource limits; `scout` and `shuttle` set only a memory limit; `scout` has no `team` label |
  | `outpost` | `drifter` | None |

- No ClusterPolicy, Policy or PolicyException yet.

## Helpers

Paste these once in each new terminal. `report_summary` lists the PolicyReports in a namespace with only the kind, name, pass and fail columns. `violations` lists the `PolicyViolation` events in a namespace.

```sh
report_summary() {
  kubectl -n "$1" get policyreports -o custom-columns='KIND:.scope.kind,NAME:.scope.name,PASS:.summary.pass,FAIL:.summary.fail'
}
violations() {
  kubectl -n "$1" get events --field-selector reason=PolicyViolation -o custom-columns=OBJECT:.involvedObject.name,MESSAGE:.message --no-headers
}
```

Use them like this: `report_summary starfleet`, `violations starfleet`.

## Practice tasks

- Before you write any policy, predict which of the four workloads break a rule that requires CPU and memory limits. Write the rule in Audit and check with `report_summary starfleet`.
- Write a validate rule that requires a `team` label on pods in `starfleet`, exclude the `kyverno` namespace, and read the rejection for a pod without the label.
- Write a mutate rule that adds `allowPrivilegeEscalation: false` to every container only when it is not set.
- Change the generate rule so it also adds the NetworkPolicy to namespaces that already exist, and check `outpost`.
- Apply a PolicyException and read the warning. Find the flag on the Kyverno controllers that explains it.
