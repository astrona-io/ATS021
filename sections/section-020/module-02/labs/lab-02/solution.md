# Solution Walkthrough

Create two Servers, repair the second backend's authorization, then attach a weighted HTTPRoute to the `scout` Service. A Server selects an inbound pod port; an AuthorizationPolicy names the authentication required to use it. An HTTPRoute configures request forwarding at the meshed client's proxy when its parent is a Service.

| Goal | Resource | Important fields |
| --- | --- | --- |
| Protect a workload port | Server | `podSelector`, `port`, `accessPolicy` |
| Allow the client identity | AuthorizationPolicy | `targetRef`, `requiredAuthenticationRefs` |
| Divide requests | HTTPRoute | `parentRefs`, `backendRefs`, `weight` |

## The feedback loop

Run grading from the host terminal where you started the lab:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-020/module-02/labs/lab-02
```

The intended start state fails `servers`, `authorization`, `route` and `observed-split`. This is the expected result of the configuration, not a recorded run. Repeat grading after each change; the proxies need time to receive policy updates.

## Inspect the missing resources and wrong reference

Read the workload labels, the missing Servers and the two policies:

```sh
kubectl -n starfleet get pods --show-labels
kubectl -n starfleet get servers.policy.linkerd.io
kubectl -n starfleet get authorizationpolicies.policy.linkerd.io -o yaml
kubectl -n starfleet get meshtlsauthentications.policy.linkerd.io -o yaml
```

Look for `probe` in the second policy's `requiredAuthenticationRefs`. Its target names the future `scout-v2-http` Server correctly. The wrong authentication selects the `probe` service account rather than the `shuttle` client. The namespace default policy blocks requests while no Server covers the ports. No check should pass yet.

## Create the two Servers

Save this as `servers-scout-versions.yaml`:

```yaml
apiVersion: policy.linkerd.io/v1beta3
kind: Server
metadata:
  name: scout-v1-http
  namespace: starfleet
spec:
  podSelector:
    matchLabels:
      app: scout
      version: v1
  port: http
  proxyProtocol: HTTP/1
  accessPolicy: deny
---
apiVersion: policy.linkerd.io/v1beta3
kind: Server
metadata:
  name: scout-v2-http
  namespace: starfleet
spec:
  podSelector:
    matchLabels:
      app: scout
      version: v2
  port: http
  proxyProtocol: HTTP/1
  accessPolicy: deny
```

Apply it:

```sh
kubectl apply -f servers-scout-versions.yaml
```

`podSelector.matchLabels` selects exactly one version per Server. `port: http` names the pod's port `9898`, rather than the Service's port `80`. `proxyProtocol` declares Hypertext Transfer Protocol (HTTP) version 1. `accessPolicy: deny` refuses requests unless an authorization permits them.

Run the check again. `servers` should pass. The existing v1 policy permits `shuttle`; the v2 policy still names the wrong identity.

## Repair the second policy

Save this as `authorizationpolicy-scout-v2-allow-shuttle.yaml`:

```yaml
apiVersion: policy.linkerd.io/v1alpha1
kind: AuthorizationPolicy
metadata:
  name: scout-v2-allow-shuttle
  namespace: starfleet
spec:
  targetRef:
    group: policy.linkerd.io
    kind: Server
    name: scout-v2-http
  requiredAuthenticationRefs:
  - group: policy.linkerd.io
    kind: MeshTLSAuthentication
    name: shuttle
```

Apply it:

```sh
kubectl apply -f authorizationpolicy-scout-v2-allow-shuttle.yaml
```

`targetRef` keeps the v2 Server as the protected resource. `requiredAuthenticationRefs` now requires `shuttle`, the existing MeshTLSAuthentication that names the client service account. Mutual Transport Layer Security (mTLS) lets the receiving proxy verify that identity from the client's certificate.

Then check the result:

```sh
kubectl -n starfleet exec deploy/shuttle -c shuttle -- curl -s -o /dev/null -w '%{http_code}\n' http://scout-v2.starfleet/api/info
kubectl -n starfleet exec deploy/caller -c caller -- curl -s -o /dev/null -w '%{http_code}\n' http://scout-v2.starfleet/api/info
kubectl -n outpost exec deploy/drifter -c drifter -- curl -s -o /dev/null -w '%{http_code}\n' http://scout-v2.starfleet/api/info
```

Look for `200` from `shuttle` and `403` from the other callers. Run the check again. `authorization` should pass once both backend proxies have the new configuration.

## Attach the weighted route to the Service

Save this as `httproute-scout-split.yaml`:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: scout-split
  namespace: starfleet
spec:
  parentRefs:
  - group: ''
    kind: Service
    name: scout
    port: 80
  rules:
  - backendRefs:
    - group: ''
      kind: Service
      name: scout-v1
      port: 80
      weight: 80
    - group: ''
      kind: Service
      name: scout-v2
      port: 80
      weight: 20
```

Apply it:

```sh
kubectl apply -f httproute-scout-split.yaml
```

The API group is `gateway.networking.k8s.io`, and the version is `v1`. `group: ""` identifies core Kubernetes Services. The parent port and backend ports are Service ports. Weights `80` and `20` select backends in an 80/20 proportion; they do not promise exact counts in a small sample.

Then check the result:

```sh
kubectl -n starfleet get httproutes.gateway.networking.k8s.io scout-split -o yaml
kubectl -n starfleet exec deploy/shuttle -c shuttle -- sh -c 'for request in $(seq 1 20); do curl -fsS --max-time 5 http://scout.starfleet/api/info; done'
```

Read the route's status for attachment errors. Look for both backend pod names in the replies' `hostname` fields. The caller still uses the same `scout` address; its outbound proxy chooses a backend for each request. This Service attachment is the Gateway API for Mesh Management and Administration (GAMMA) model. No Gateway resource is needed.

Run the check again:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-020/module-02/labs/lab-02
```

`route` should pass on the resource fields. `observed-split` sends 400 requests from `shuttle` and matches each hostname against live pod names. It permits 40–120 v2 replies and requires all requests to succeed.

## If a check stays red

- **`servers`:** Compare both selectors and use the named pod port `http`. A selector for `app: scout` alone covers both versions and can overlap the other Server.
- **`authorization`:** Check the required authentication, its service account and the Server target. Deleting the broken policy or allowing unauthenticated requests does not meet the task.
- **`route`:** Use the Gateway API group, a core Service parent and both weights. The similarly named Linkerd policy HTTPRoute is a different resource type.
- **`observed-split`:** Confirm `shuttle` has a proxy and both versioned Services answer it. A ServiceProfile for `scout` takes precedence over the outbound HTTPRoute; keep that resource absent. If the route has just changed, wait for configuration to reach the proxy and submit again.
