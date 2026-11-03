# Overview: Admit Only Trusted Images (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with two
policy engines and two namespaces, and then waits. There is no task, no
`astrona submit` and no pass or fail. Write image policies, test them with
server-side dry runs, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already
  pointed at it.
- **Kyverno 1.19.1** and **Gatekeeper 3.23.1**, both admission controllers
  with ready webhooks. Gatekeeper evaluates Rego policy code with Open Policy
  Agent (OPA).

  | Namespace | Label | Workloads |
  | --- | --- | --- |
  | `starfleet` | `environment: development` | `scout` (`ghcr.io/stefanprodan/podinfo:6.15.0`) |
  | `starfleet-prod` | `environment: production` | none |

- One image already on the node: `ghcr.io/stefanprodan/podinfo:6.15.0`. A
  server-side dry run never pulls an image, so other references such as
  `nginx:latest` need no preload.
- No Kyverno ClusterPolicy, no Gatekeeper ConstraintTemplate and no
  Constraint yet.

## Helpers

Paste these once in each new terminal. `try_image` asks the API server,
without storing anything, whether a Deployment with the given image is
accepted in a namespace. `podinfo_digest` prints the digest that the
`podinfo:6.15.0` tag points at.

```sh
try_image() {
  kubectl -n "$1" create deployment image-test --image="$2" --dry-run=server
}
podinfo_digest() {
  echo "sha256:ec73780a8425f59ea49f5bc8cdff0d598805a224fbaa1f86c67a244f250fa9da"
}
```

Use them like this: `try_image starfleet-prod nginx:latest` and
`try_image starfleet-prod ghcr.io/stefanprodan/podinfo@$(podinfo_digest)`.

## Practice tasks

- Write a Kyverno ClusterPolicy that admits images only from `ghcr.io/` and
  prove it with `nginx:latest` (rejected) and `podinfo:6.15.0` (accepted).
- Add a rule that rejects the `latest` tag and images with no tag at all.
- Require images pinned by digest, but only in `starfleet-prod`.
- Write the same allowed-registry rule as a Gatekeeper ConstraintTemplate
  and Constraint, and compare the two rejection messages.
