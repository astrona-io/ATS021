# Question

Solve this question on: `terminal`

## Scenario

The `starfleet` namespace runs two versions of the `scout` backend and two clients. Linkerd edge-26.10.1 and the Gateway API custom resource definitions (CRDs) v1.4.0 are installed. A CRD adds a resource type to the Kubernetes application programming interface (API). Nothing in `starfleet` is in the mesh yet: no pod has a Linkerd proxy, the sidecar that handles a pod's traffic.

The Deployments `scout-v1` and `scout-v2` both run as the `scout` service account, carry the labels `app: scout` and `version: v1` or `version: v2`, and listen on the named container port `http` (`9898`). The Services `scout-v1`, `scout-v2` and `scout` each listen on port `80`; `scout` selects only v1. The `shuttle` Deployment runs as the `shuttle` service account. The `caller` Deployment runs as the `probe` service account.

A security review found two faults. The `MeshTLSAuthentication` named `scout-callers` lists the `probe` service account, but the only client allowed to reach `scout` is `shuttle`. A MeshTLSAuthentication names the mesh identities a policy allows; the identity comes from the client proxy's certificate under mutual Transport Layer Security (mTLS), where both proxies present a certificate. The `AuthorizationPolicy` named `scout-allow-shuttle` targets a `Server` called `scout-http`, which nobody created. A Server selects one port on a set of pods for inbound policy; an AuthorizationPolicy says which authentication a client needs to use it.

Use only the API versions this cluster serves. Find them before you write any resource:

```sh
kubectl api-resources --api-group=policy.linkerd.io
kubectl api-resources --api-group=gateway.networking.k8s.io
```

The `APIVERSION` column shows the version to put in `apiVersion`. The HTTPRoute for this task is the one in the `gateway.networking.k8s.io` group, not the one in `policy.linkerd.io`.

## Tasks

1. **Mesh the namespace.** Every pod of `scout-v1`, `scout-v2`, `shuttle` and `caller` must run a Linkerd proxy, so all traffic between them uses mTLS. Use the `linkerd.io/inject: enabled` annotation on the `starfleet` namespace. The proxy joins only pods created after the annotation; make sure each Deployment finishes a new rollout. Keep each Deployment's service account, labels and container unchanged.

2. **Protect the backend port.** Create a `Server` named `scout-http` in `starfleet`. It must select both versions with `podSelector.matchLabels` set to `app: scout` and nothing else, select the pod port `http`, declare `proxyProtocol: HTTP/1`, and set `accessPolicy: deny` so a request without an authorization gets `403`. Create no other Server.

3. **Allow exactly one caller.** Repair `scout-callers` so its only `identityRefs` entry is the `ServiceAccount` named `shuttle`. Keep `scout-allow-shuttle` as the only AuthorizationPolicy in `starfleet`; it must keep targeting the Server `scout-http` and require only `scout-callers`. Do not change the service account of `shuttle` or `caller`. When you are done, `shuttle` must get `200` and `caller` must get `403` from both `http://scout-v1.starfleet/api/info` and `http://scout-v2.starfleet/api/info`.

4. **Split traffic between the two versions.** Create an `HTTPRoute` named `scout-split` in `starfleet` in the `gateway.networking.k8s.io` group. Its single `parentRefs` entry must be the core Service `scout` on port `80` (`group: ""`, `kind: Service`). Use one rule with two core Service `backendRefs`: `scout-v1` on port `80` with weight `75` and `scout-v2` on port `80` with weight `25`. Omit hostnames and filters, and let the rule cover all paths: omit `matches` or use the default `PathPrefix` match for `/`. Linkerd's policy controller must report the route as accepted for the parent `scout`; read `status.parents` on the route. Across 400 successful requests from `shuttle` to `http://scout.starfleet/api/info`, v2 must answer between 15% and 35% of them, and every reply must come from one of the live backend pods.
