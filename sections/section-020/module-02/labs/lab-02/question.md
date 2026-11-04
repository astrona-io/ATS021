# Question

Solve this question on: `terminal`

## Scenario

The `shuttle` client in `starfleet` must reach two versions of `scout` during a release. Linkerd edge-26.10.1 and Gateway API custom resource definitions (CRDs) v1.4.0 are installed. A CRD adds a resource type to the Kubernetes application programming interface (API).

The `scout-v1` and `scout-v2` Deployments and Services already exist. Each Service listens on port `80` and selects its own version. The parent Service `scout` currently selects only v1. Both backends and the `shuttle` and `caller` clients are meshed: each pod has a Linkerd proxy. `caller` uses the `probe` service account; `drifter` in `outpost` has no proxy.

There are no Servers or HTTPRoutes. The namespace's default inbound policy is `deny`, so requests start blocked. Two AuthorizationPolicies target the missing Servers. The v1 policy requires `shuttle`, but `scout-v2-allow-shuttle` incorrectly requires the `probe` MeshTLSAuthentication. A MeshTLSAuthentication lists allowed identities for mutual Transport Layer Security (mTLS), where both proxies present certificates.

## Tasks

1. **Protect both workload ports.** In `starfleet`, create `Server` resources `scout-v1-http` and `scout-v2-http` using `policy.linkerd.io/v1beta3`. For each Server, set `podSelector.matchLabels` to `app: scout` and its `version: v1` or `version: v2`, `port: http`, `proxyProtocol: HTTP/1` and `accessPolicy: deny`. A Server selects a pod port for inbound policy.

2. **Repair authorization.** An AuthorizationPolicy connects a protected resource to required authentication. Keep both named policies and their Server targets. Repair `scout-v2-allow-shuttle` so that, like `scout-v1-allow-shuttle`, it requires only the existing `MeshTLSAuthentication` named `shuttle` in group `policy.linkerd.io`. That authentication must keep only its `ServiceAccount` identity reference to `shuttle`. Both backend Services must return `200` to `shuttle` and `403` to `caller` and `drifter`. Keep the workload identities, proxies, Service selectors and default inbound policy in place.

3. **Split requests by weight.** Create `scout-split` in `starfleet` with `apiVersion: gateway.networking.k8s.io/v1` and `kind: HTTPRoute`. An HTTPRoute defines how proxies match and forward Hypertext Transfer Protocol (HTTP) requests. Its sole `parentRefs` entry must be the core Service `scout` (`group: ""`, `kind: Service`, `port: 80`). Use one rule with two core Service `backendRefs`: `scout-v1` on port `80`, weight `80`, and `scout-v2` on port `80`, weight `20`. Omit backend namespaces, hostnames and filters. The rule must cover all paths: omit `matches` or use the default `PathPrefix` match for `/`. Keep `shuttle` meshed: a Service-attached route runs at the client's proxy. Across 400 successful requests to `http://scout.starfleet/api/info`, v2 must receive 10–30% of replies, a tolerance of 10 percentage points around 20%. Each reply must identify one of the live backend pods.
