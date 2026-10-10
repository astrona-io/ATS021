# Overview: Write ValidatingAdmissionPolicies With CEL (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with the
example workloads, and then waits. There is no task, no `astrona submit` and
no pass or fail. Write policies and bindings, change their actions,
`astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already
  pointed at it.
- **No policy engine.** A `ValidatingAdmissionPolicy` is a built-in
  Kubernetes resource: the API server itself evaluates its Common Expression
  Language (CEL) expressions, with no webhook.

  | Namespace | Label | Workloads | Deliberate gaps |
  | --- | --- | --- | --- |
  | `starfleet` | `environment: production` | `scout`, `probe`, `shuttle` | `scout` runs 8 replicas |
  | `outpost` | `environment: sandbox` | `drifter` | none |

- A ConfigMap `replica-limits` in `starfleet` with `maxReplicas: "5"`, to use
  as the params resource of a policy.
- No `ValidatingAdmissionPolicy` and no `ValidatingAdmissionPolicyBinding` yet.

## Helpers

Paste these once in each new terminal. `list_policies` shows every policy and
binding in the cluster. `try_replicas` asks the API server, without storing
anything, whether `scout` in a namespace may run a given number of replicas.

```sh
list_policies() {
  kubectl get validatingadmissionpolicies,validatingadmissionpolicybindings
}
try_replicas() {
  kubectl -n "$1" scale deployment scout --replicas="$2" --dry-run=server
}
```

Use them like this: `list_policies` and `try_replicas starfleet 6`.
`try_replicas` needs a `scout` Deployment in the namespace you name.

## Practice tasks

- Write a policy that limits Deployments to at most 5 replicas and bind it to
  namespaces labelled `environment: production` with `Deny`. Then try to
  scale `scout` to 6.
- Change the binding to `[Warn, Audit]` and compare the answer of the same
  scale request.
- Read the limit from the `replica-limits` ConfigMap with `paramKind` and
  `paramRef` instead of writing `5` in the expression. Change the ConfigMap
  to `3` and predict which requests fail.
- Add a `messageExpression` that prints the requested replica count in the
  error message.
- Write a second policy that rejects a Deployment whose containers use the
  image tag `latest`, and test it with a server-side dry run.
