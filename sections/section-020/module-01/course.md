# Require Mutual TLS And Authorize Callers With Istio

Inside a cluster, any pod can open a connection to any Service, in plain text, without saying who it is. A NetworkPolicy can limit which IP addresses connect, but it cannot prove which workload is on the other end, and it does not encrypt anything. A service mesh changes that. Istio puts a proxy next to each workload, gives each workload a certificate that names its service account, and lets you require that every connection uses mutual TLS and comes from an identity you allow.

Keep one sentence in mind for this module: **PeerAuthentication decides whether a connection must be mutual TLS, and AuthorizationPolicy decides which identity may make which request.** You will read the identity in a workload's certificate, switch a namespace to STRICT mutual TLS and watch a plain-text client fail, allow only one service account to call `scout`, and read the `403` that every other caller gets.

The module has three parts. **Mesh Identity And mTLS Modes** shows the sidecar, the workload certificate and the SPIFFE identity inside it, and why the mesh accepts plain text at the start. **Requiring STRICT Mutual TLS** turns on STRICT with a PeerAuthentication, proves that plain text is refused, and finds the workload without a sidecar that breaks. **Authorizing Callers** writes AuthorizationPolicies, reads the `RBAC: access denied` answer, and works out which policy wins when several match.

## Learning objectives

After this module you can:

- Name the SPIFFE identity a workload presents from its namespace and service account.
- Switch a namespace from PERMISSIVE to STRICT mTLS with PeerAuthentication and prove plain-text traffic is refused.
- Write an AuthorizationPolicy that allows only the `shuttle` service account to call `scout` with GET.
- Read a `403` `RBAC: access denied` response and name the policy and rule that decided it.
- Order ALLOW, DENY and CUSTOM policies and predict the result when several match.
- Find the workload whose sidecar is missing and so breaks STRICT mTLS.

## Before you start

You need Kubernetes basics: pods, Deployments, Services, service accounts and labels, and the commands `kubectl get`, `kubectl apply` and `kubectl exec`. You also need `jq` and `openssl` on your machine to read one certificate. You do not need to know Istio's traffic routing.

Your playground is a single-node `kind` cluster running Kubernetes 1.35 with **Istio 1.31.1**, installed with the `minimal` profile: the control plane `istiod` only, no gateways. `istioctl` 1.31.1 is on your PATH. Each workload runs on a service account with its own name:

| Namespace | Workloads | Sidecar injection |
| --- | --- | --- |
| `starfleet` | `scout` (`podinfo` on port `9898`, Service port `80`), `probe` (`go-httpbin` on port `8080`, Service port `80`), `shuttle` (a client with `curl`) | On (`istio-injection=enabled`), so every pod shows `2/2` |
| `outpost` | `drifter` (a client with `curl`) | Off, so `drifter` sends plain-text requests |

There is no PeerAuthentication and no AuthorizationPolicy yet. The mesh starts in Istio's default PERMISSIVE mode on purpose, so `drifter` can still reach `scout`. `kubectl` already points at the playground cluster.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
