# Summary

A service mesh gives every workload a verified identity and lets you require it on every connection. In Istio, PeerAuthentication decides whether a connection must be mutual TLS, and AuthorizationPolicy decides which identity may make which request.

## What you learned

Istio's mutating webhook adds the `istio-proxy` sidecar to pods in a namespace labelled `istio-injection=enabled`; on Kubernetes 1.33 and later it is a native sidecar under `initContainers`. `istiod` gives each sidecar a short-lived certificate whose subject alternative name is the SPIFFE identity `spiffe://cluster.local/ns/<namespace>/sa/<service account>`. The identity comes only from the namespace and the service account. Policies write it as the principal `cluster.local/ns/<namespace>/sa/<name>`.

Istio starts in PERMISSIVE mode, where a sidecar accepts both mTLS and plain text. A PeerAuthentication with `mode: STRICT` makes the sidecars accept only mTLS, at mesh, namespace or workload scope, and the most specific one wins. Under STRICT, a client without a sidecar gets a reset connection (`curl` exit code `56`), not an HTTP status. A pod with the label `sidecar.istio.io/inject: "false"` has no sidecar and so no identity, even when it uses a service account that has one; `istioctl x check-inject` names the reason.

An AuthorizationPolicy selects workloads, has an action, and has rules made of `from`, `to` and `when`. A refused request gets `403` with the body `RBAC: access denied` from Envoy. CUSTOM and DENY policies are checked before ALLOW, so a matching DENY always wins. Once a workload has any ALLOW policy, only matching requests are allowed. An empty `spec` is the default-deny policy for a namespace. `istioctl x authz check` lists the policies that apply to a workload. The key facts to remember are these:

- Identity is namespace plus service account; give each workload its own service account.
- STRICT refuses plain text with a reset connection; AuthorizationPolicy refuses requests with `403`.
- DENY before ALLOW; any ALLOW policy turns a workload into allow-list mode.
- Fix a client that breaks under STRICT by giving it a sidecar, not by going back to PERMISSIVE.

<!-- astrona:playground:destroy -->
