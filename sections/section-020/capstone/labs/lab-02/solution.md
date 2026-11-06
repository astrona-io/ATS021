# Solution Walkthrough

Put the namespace in the mesh, protect the backend port with a Server, repair the authentication so only `shuttle` passes the AuthorizationPolicy, and attach a weighted HTTPRoute to the `scout` Service. The order matters: the Server and the policy only take effect on pods that have a Linkerd proxy, and the route only acts at a meshed client's proxy.

| Goal | Resource | Important fields |
| --- | --- | --- |
| Put pods in the mesh | Namespace annotation | `linkerd.io/inject: enabled`, then a rollout restart |
| Protect a workload port | Server | `podSelector`, `port`, `proxyProtocol`, `accessPolicy` |
| Allow one identity | MeshTLSAuthentication, AuthorizationPolicy | `identityRefs`, `targetRef`, `requiredAuthenticationRefs` |
| Divide requests | HTTPRoute | `parentRefs`, `backendRefs`, `weight`, `status.parents` |

## The feedback loop

Keep this command running in a second host terminal. It grades the lab every few seconds and records nothing:

```sh
astrona submit --watch --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-020/capstone/labs/lab-02
```

Use `--watch` until the end, because a plain `astrona submit` finishes the attempt and deletes the lab. Run the plain command once, in the last step.

The intended start state fails all five checks: `namespace-meshed`, `server-protects-scout`, `only-shuttle-allowed`, `route-attached` and `observed-split`. This is the expected result of the configuration, not a recorded run. The watch terminal updates after each change; the proxies need a few seconds to receive new policy.

## Find the API versions and the faults

Ask the API server which versions it serves for the resource kinds you need:

```sh
kubectl api-resources --api-group=policy.linkerd.io
kubectl api-resources --api-group=gateway.networking.k8s.io
```

Look at the `APIVERSION` column. Linkerd edge-26.10.1 serves `Server` at `policy.linkerd.io/v1beta3` and `AuthorizationPolicy` and `MeshTLSAuthentication` at `policy.linkerd.io/v1alpha1`. The Gateway API CRDs v1.4.0 serve `HTTPRoute` at `gateway.networking.k8s.io/v1`. The `policy.linkerd.io` group also lists an `HTTPRoute`; that is Linkerd's own kind and not the one this task asks for.

Then read the start state:

```sh
kubectl get namespace starfleet -o jsonpath='{.metadata.annotations}{"\n"}'
kubectl -n starfleet get pods -o custom-columns='NAME:.metadata.name,CONTAINERS:.spec.containers[*].name,INIT:.spec.initContainers[*].name'
kubectl -n starfleet get servers.policy.linkerd.io
kubectl -n starfleet get meshtlsauthentications.policy.linkerd.io scout-callers -o yaml
kubectl -n starfleet get authorizationpolicies.policy.linkerd.io scout-allow-shuttle -o yaml
```

Look for a namespace with no `linkerd.io/inject` annotation and pods with no `linkerd-proxy` container. There is no Server. The authentication's `identityRefs` names `probe`, the service account of `caller`, which is the wrong one. The policy targets the Server `scout-http` that does not exist yet.

## Mesh the namespace

Annotate the namespace, then restart every Deployment, because the proxy injector only adds a proxy to pods created after the annotation:

```sh
kubectl annotate namespace starfleet linkerd.io/inject=enabled
kubectl -n starfleet rollout restart deployment scout-v1 scout-v2 shuttle caller
kubectl -n starfleet rollout status deployment scout-v1 --timeout=180s
kubectl -n starfleet rollout status deployment scout-v2 --timeout=180s
kubectl -n starfleet rollout status deployment shuttle --timeout=180s
kubectl -n starfleet rollout status deployment caller --timeout=180s
```

Then check the result:

```sh
kubectl -n starfleet get pods -o custom-columns='NAME:.metadata.name,CONTAINERS:.spec.containers[*].name,INIT:.spec.initContainers[*].name'
```

Look for `linkerd-init` and `linkerd-proxy` on every pod. Linkerd runs the proxy as a native sidecar, so it appears under the init containers. The watch terminal shows `namespace-meshed` passing once the old pods are gone. Both backends now answer every meshed client, because no Server covers the port and the cluster default inbound policy allows traffic.

## Protect the port with a Server

Save this as `server-scout-http.yaml`:

```yaml
apiVersion: policy.linkerd.io/v1beta3
kind: Server
metadata:
  name: scout-http
  namespace: starfleet
spec:
  podSelector:
    matchLabels:
      app: scout
  port: http
  proxyProtocol: HTTP/1
  accessPolicy: deny
```

Apply it:

```sh
kubectl apply -f server-scout-http.yaml
```

`podSelector.matchLabels` with only `app: scout` covers both versions with one Server. `port: http` names the pod port `9898`, not the Service port `80`. `proxyProtocol` declares Hypertext Transfer Protocol (HTTP) version 1, and `accessPolicy: deny` refuses every request that no authorization allows.

Then check the result:

```sh
kubectl -n starfleet get servers.policy.linkerd.io
kubectl -n starfleet exec deploy/shuttle -c shuttle -- curl -s -o /dev/null -w '%{http_code}\n' http://scout-v1.starfleet/api/info
```

Look for `403` from `shuttle`. The policy `scout-allow-shuttle` now targets a Server that exists, but the authentication it requires still names `probe`, so `shuttle` is refused and `caller` would pass. The watch terminal shows `server-protects-scout` passing.

## Repair the authentication

Save this as `meshtlsauthentication-scout-callers.yaml`:

```yaml
apiVersion: policy.linkerd.io/v1alpha1
kind: MeshTLSAuthentication
metadata:
  name: scout-callers
  namespace: starfleet
spec:
  identityRefs:
  - kind: ServiceAccount
    name: shuttle
```

Apply it:

```sh
kubectl apply -f meshtlsauthentication-scout-callers.yaml
```

`identityRefs` with `kind: ServiceAccount` names the mesh identity `shuttle.starfleet.serviceaccount.identity.linkerd.cluster.local`, which the `shuttle` proxy carries in its certificate. The AuthorizationPolicy stays as it is: it already targets `scout-http` and requires `scout-callers`.

Then check the result:

```sh
kubectl -n starfleet exec deploy/shuttle -c shuttle -- curl -s -o /dev/null -w '%{http_code}\n' http://scout-v1.starfleet/api/info
kubectl -n starfleet exec deploy/shuttle -c shuttle -- curl -s -o /dev/null -w '%{http_code}\n' http://scout-v2.starfleet/api/info
kubectl -n starfleet exec deploy/caller -c caller -- curl -s -o /dev/null -w '%{http_code}\n' http://scout-v1.starfleet/api/info
kubectl -n starfleet exec deploy/caller -c caller -- curl -s -o /dev/null -w '%{http_code}\n' http://scout-v2.starfleet/api/info
```

Look for `200` from `shuttle` and `403` from `caller` on both versions. A refused request gets `403` with an empty body. The watch terminal shows `only-shuttle-allowed` passing once both backend proxies have the new policy.

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
  - group: ""
    kind: Service
    name: scout
    port: 80
  rules:
  - backendRefs:
    - name: scout-v1
      port: 80
      weight: 75
    - name: scout-v2
      port: 80
      weight: 25
```

Apply it:

```sh
kubectl apply -f httproute-scout-split.yaml
```

`group: ""` on the parent means a core Kubernetes Service; without it the parent defaults to a Gateway. The parent port and the backend ports are Service ports. A `backendRefs` entry defaults to a core Service in the route's namespace. Weights `75` and `25` set the proportion; a small sample will not show it exactly. Attaching the route to a Service is the Gateway API for Mesh Management and Administration (GAMMA) model: the meshed client's outbound proxy applies it, and no Gateway is needed.

Then check the result:

```sh
kubectl -n starfleet get httproutes.gateway.networking.k8s.io scout-split -o jsonpath='{range .status.parents[*]}{.controllerName}{" "}{.parentRef.name}{" "}{range .conditions[*]}{.type}={.status} {end}{"\n"}{end}'
kubectl -n starfleet exec deploy/shuttle -c shuttle -- sh -c 'for request in $(seq 1 20); do curl -fsS --max-time 5 http://scout.starfleet/api/info; done'
```

Look for one status line from `linkerd.io/policy-controller` for the parent `scout` with `Accepted=True` and `ResolvedRefs=True`. `Accepted` means the policy controller found the parent Service; `ResolvedRefs` means it found both backend Services. In the replies, look for both backend pod names in the `hostname` field. The watch terminal shows `route-attached` passing, then `observed-split` after its 400 requests.

Press Ctrl-C to stop the watch, then run the check once:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-020/capstone/labs/lab-02
```

`observed-split` sends 400 requests from `shuttle` to `scout` and matches each `hostname` against the live pod names. It requires all requests to succeed and between 60 and 140 v2 replies.

## If a check stays red

- **`namespace-meshed`:** The annotation value must be `enabled` and every Deployment needs a new rollout. A pod that existed before the annotation never gets a proxy.
- **`server-protects-scout`:** The selector must be `app: scout` alone, the port the named pod port `http`, and there must be only one Server. A selector with a `version` label leaves the other version unprotected.
- **`only-shuttle-allowed`:** Fix the authentication, not the callers. Changing the service account of `caller`, adding a second AuthorizationPolicy, deleting `scout-allow-shuttle` or allowing unauthenticated requests does not meet the task.
- **`route-attached`:** Use the `gateway.networking.k8s.io` group, a core Service parent with `group: ""`, both weights, and wait for the policy controller to write the status. A missing backend Service shows as `ResolvedRefs=False`.
- **`observed-split`:** Confirm `shuttle` has a proxy and both versioned Services answer it with `200`. A ServiceProfile for `scout` takes precedence over the outbound HTTPRoute; keep that resource absent. If the route has just changed, wait for the configuration to reach the proxy and watch the result again.
