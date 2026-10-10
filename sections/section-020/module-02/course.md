# Require Mutual TLS And Authorize Callers With Linkerd

Linkerd is the second service mesh the CNPE exam lists, and the exam may let you choose it instead of Istio. It solves the same problem, an identity on every connection and a rule for who may call whom, with fewer moving parts. Linkerd turns on mutual TLS between meshed pods by itself, with no setting at all. Authorization is a separate step, built from a default policy and three small resources.

Keep one sentence in mind for this module: **meshed traffic is encrypted automatically, and a Server plus an AuthorizationPolicy decides who may use a port.** You will confirm that traffic between meshed pods is already mutual TLS, read a workload's Linkerd identity, close a namespace to unauthenticated callers with one annotation, and then allow only `shuttle` to call `scout`.

The module has two parts. **Automatic mTLS, Identity And Default Policy** shows Linkerd's identity, proves which connections use TLS, and sets the default inbound policy. **Servers And Authorization Policies** selects `scout`'s port with a Server, names the allowed identity with a MeshTLSAuthentication and connects them with an AuthorizationPolicy.

## Learning objectives

After this module you can:

- Inject the Linkerd proxy into a namespace and confirm with `linkerd viz` that connections use mTLS.
- Name the Linkerd identity of a workload from its service account.
- Write a Server and an AuthorizationPolicy with a MeshTLSAuthentication that let only `shuttle` call `scout`.
- Set a default inbound policy (`all-unauthenticated`, `all-authenticated`, `deny`) and predict who is refused.
- Map each Linkerd resource to the Istio resource that does the same job.

## Before you start

You need Kubernetes basics: pods, Deployments, Services, service accounts, labels and annotations, and the commands `kubectl get`, `kubectl apply` and `kubectl exec`. It helps to know what mutual TLS is: both sides of a connection present a certificate, so each side proves its identity and the traffic is encrypted.

Your playground is a single-node `kind` cluster running Kubernetes 1.35 with **Linkerd edge-26.10.1**, the control plane and the `viz` extension, which adds metrics and live request views. The `linkerd` command is on your PATH. Each workload runs on a service account with its own name:

| Namespace | Workloads | Proxy injection |
| --- | --- | --- |
| `starfleet` | `scout` (`podinfo`, Service port `80`), `probe` (`go-httpbin`, Service port `80`), `shuttle` (a client with `curl`) | On (annotation `linkerd.io/inject: enabled`), so every pod shows `2/2` |
| `outpost` | `drifter` (a client with `curl`) | Off, so `drifter` sends plain-text requests |

The default inbound policy is `all-unauthenticated` and there is no Server or AuthorizationPolicy yet, so `drifter` can reach `scout` at the start. `kubectl` already points at the playground cluster.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
