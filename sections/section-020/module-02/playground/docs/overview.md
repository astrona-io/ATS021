# Overview: Require Mutual TLS And Authorize Callers With Linkerd (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with Linkerd and the example workloads, and then waits. There is no task, no `astrona submit` and no pass or fail. Change the default policy, write Servers and AuthorizationPolicies, break them, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it.
- **Linkerd edge-26.10.1** with the `viz` extension, and the `linkerd` command on your PATH. Policy resources: `Server` (`policy.linkerd.io/v1beta3`), `AuthorizationPolicy` and `MeshTLSAuthentication` (`v1alpha1`).

  | Namespace | Workloads (each on its own service account) | Proxy |
  | --- | --- | --- |
  | `starfleet` | `scout` (`podinfo`, container port `http` 9898, Service port `80`), `probe` (`go-httpbin`, Service port `80`), `shuttle` (client with `curl`) | Injected, pods show `2/2` |
  | `outpost` | `drifter` (client with `curl`) | None, sends plain text |

- The default inbound policy is `all-unauthenticated`. There is no Server and no AuthorizationPolicy, so `drifter` can reach `scout` at the start.

## Helpers

Paste these once in each new terminal. `from_shuttle` and `from_drifter` send one request to a URL and print only the HTTP status. `inbound_policy` restarts a Deployment in `starfleet` so its proxy reads a changed default inbound policy annotation.

```sh
from_shuttle() {
  kubectl -n starfleet exec deploy/shuttle -c shuttle -- curl -s -o /dev/null -w '%{http_code}\n' "$@"
}
from_drifter() {
  kubectl -n outpost exec deploy/drifter -- curl -s -o /dev/null -w '%{http_code}\n' "$@"
}
inbound_policy() {
  kubectl -n starfleet rollout restart "deployment/$1" && kubectl -n starfleet rollout status "deployment/$1"
}
```

Use them like this: `from_shuttle http://scout.starfleet`, `from_drifter http://probe.starfleet/get`, `inbound_policy scout`.

## Practice tasks

- Before you change anything, run `linkerd viz edges deployment -n starfleet` and predict whether `drifter` appears in it. Then send traffic and check.
- Set the default inbound policy to `deny` on the `probe` pods only (a pod template annotation), and predict what `from_shuttle http://probe.starfleet/get` returns.
- Create a Server for `scout` and nothing else, and check who can still reach `scout`.
- Allow both `shuttle` and `probe` to call `scout` with one MeshTLSAuthentication that lists two service accounts.
- Write the Istio resources that would do the same job as your Linkerd policy, without applying them.
