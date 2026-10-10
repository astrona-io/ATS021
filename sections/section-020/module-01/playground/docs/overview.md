# Overview: Require Mutual TLS And Authorize Callers With Istio (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with Istio and the example workloads, and then waits. There is no task, no `astrona submit` and no pass or fail. Write PeerAuthentications and AuthorizationPolicies, break them, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it.
- **Istio 1.31.1**, installed with the `minimal` profile (`istiod` only, no gateways), and `istioctl` 1.31.1 on your PATH.

  | Namespace | Workloads (each on its own service account) | Sidecar |
  | --- | --- | --- |
  | `starfleet` | `scout` (`podinfo`, Service port `80`), `probe` (`go-httpbin`, Service port `80`), `shuttle` (client with `curl`) | Injected, pods show `2/2` |
  | `outpost` | `drifter` (client with `curl`) | None, sends plain text |

- No PeerAuthentication and no AuthorizationPolicy. The mesh is PERMISSIVE, so `drifter` can reach `scout` at the start.

## Helpers

Paste these once in each new terminal. `from_shuttle` and `from_drifter` send one request to a URL and print only the HTTP status (or the `curl` error). `identity_of` prints the SPIFFE identity in a workload's certificate (it needs `jq` and `openssl`).

```sh
from_shuttle() {
  kubectl -n starfleet exec deploy/shuttle -c shuttle -- curl -sS -o /dev/null -w '%{http_code}\n' "$@"
}
from_drifter() {
  kubectl -n outpost exec deploy/drifter -- curl -sS -o /dev/null -w '%{http_code}\n' "$@"
}
identity_of() {
  istioctl proxy-config secret "deploy/$1" -n "${2:-starfleet}" -o json \
    | jq -r '.dynamicActiveSecrets[] | select(.name=="default") | .secret.tlsCertificate.certificateChain.inlineBytes' \
    | base64 -d | openssl x509 -noout -ext subjectAltName
}
```

Use them like this: `from_shuttle http://scout.starfleet`, `from_drifter http://probe.starfleet/get`, `identity_of probe`.

## Practice tasks

- Before you add any policy, predict what `from_drifter http://scout.starfleet` returns under PERMISSIVE and under STRICT. Then check both.
- Make only `scout` STRICT with a workload-level PeerAuthentication, and leave `probe` PERMISSIVE. Prove the difference from `drifter`.
- Allow `GET` on `probe` only from callers in the `starfleet` namespace, using `from.source.namespaces` instead of `principals`.
- Add a DENY policy and an ALLOW policy that both match the same request, and predict the answer before you send it.
- Start a pod in `starfleet` with the label `sidecar.istio.io/inject: "false"` and find it with `istioctl x check-inject`.
