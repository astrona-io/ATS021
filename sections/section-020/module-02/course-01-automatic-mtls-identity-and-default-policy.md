# Automatic mTLS, Identity And Default Policy

In Linkerd, there is no switch for mutual TLS. Every connection between two meshed pods uses it from the moment both pods have a proxy. What Linkerd does not do by default is refuse callers without a proxy. This part shows the identity Linkerd gives each workload, proves which connections are encrypted, and then closes `starfleet` to callers without an identity.

## The proxy and the identity

**Proxy injection** works like Istio's sidecar injection: Linkerd's mutating webhook adds a `linkerd-proxy` container to every pod created in a namespace or pod with the annotation `linkerd.io/inject: enabled`. List the containers of the `scout` pod:

<!-- astrona:playground:renew -->

```sh
kubectl -n starfleet get pod -l app=scout -o jsonpath='{.items[0].spec.initContainers[*].name}{" | "}{.items[0].spec.containers[*].name}{"\n"}'
```

You should see:

```text
linkerd-init linkerd-proxy | scout
```

As with Istio on Kubernetes 1.33 and later, the proxy is a native sidecar under `initContainers`, and `linkerd-init` sets up the network rules first. When the proxy starts, it proves its service account to the `linkerd-identity` service with the pod's service account token, and gets a certificate. `linkerd identity` prints it:

```sh
linkerd identity -n starfleet -l app=scout | grep -E 'Subject:|DNS:'
```

You should see:

```text
        Subject: CN=scout.starfleet.serviceaccount.identity.linkerd.cluster.local
                DNS:scout.starfleet.serviceaccount.identity.linkerd.cluster.local
```

A Linkerd identity has the form `<service account>.<namespace>.serviceaccount.identity.linkerd.<trust domain>`. Like Istio's SPIFFE identity, it comes only from the service account and the namespace; only the spelling differs.

## Which connections use TLS

Two commands of the `viz` extension show what the proxies see. `linkerd viz edges` lists connections between meshed workloads and whether they are secured with mTLS. Send some requests from `shuttle` first, then wait about half a minute for the metrics to arrive:

```sh
kubectl -n starfleet exec deploy/shuttle -c shuttle -- sh -c 'for i in $(seq 1 20); do curl -s -o /dev/null http://scout.starfleet; sleep 1; done'
linkerd viz edges deployment -n starfleet
```

You should see something like:

```text
SRC          DST       SRC_NS        DST_NS      SECURED
prometheus   probe     linkerd-viz   starfleet   √      
prometheus   scout     linkerd-viz   starfleet   √      
prometheus   shuttle   linkerd-viz   starfleet   √      
shuttle      scout     starfleet     starfleet   √      
```

The `shuttle` to `scout` connection is secured, and you configured nothing for it. The `prometheus` rows are the `viz` extension collecting metrics from each proxy, also over mTLS. `drifter` does not appear, because it has no proxy and so is not part of any edge.

`linkerd viz tap` shows individual requests as they arrive at a workload, with a `tls` field. Run it in one terminal, and send one request from `drifter` to `scout` from a second terminal:

```sh
linkerd viz tap deploy/scout -n starfleet --path /version
```

```sh
kubectl -n outpost exec deploy/drifter -- curl -s -o /dev/null http://scout.starfleet/version
```

The first terminal prints something like:

```text
req id=1:0 proxy=in  src=10.244.0.16:53092 dst=10.244.0.13:9898 tls=no_tls_from_remote :method=GET :authority=scout.starfleet :path=/version
rsp id=1:0 proxy=in  src=10.244.0.16:53092 dst=10.244.0.13:9898 tls=no_tls_from_remote :status=200 latency=486µs
end id=1:0 proxy=in  src=10.244.0.16:53092 dst=10.244.0.13:9898 tls=no_tls_from_remote duration=17µs response-length=0B
```

`tls=no_tls_from_remote` means the caller sent plain text, and `:status=200` means `scout`'s proxy let it through. A request from `shuttle` shows `tls=true` instead. Stop `tap` with `Ctrl+C`.

## The default inbound policy

What a proxy does with a caller that no specific rule covers is set by its **default inbound policy**. The cluster-wide default is `all-unauthenticated`. The values are:

| Value | Who may connect |
| --- | --- |
| `all-unauthenticated` | Everyone, with or without mTLS |
| `all-authenticated` | Only meshed clients with a valid identity, from any namespace |
| `cluster-unauthenticated` | Everyone whose IP address is inside the cluster's networks |
| `cluster-authenticated` | Only meshed clients from inside the cluster's networks |
| `deny` | Nobody, unless a policy resource allows it |

The annotation `config.linkerd.io/default-inbound-policy` on a namespace or a pod changes it. The proxy reads the value when it starts, so annotate the namespace, then restart the workload:

```sh
kubectl annotate namespace starfleet config.linkerd.io/default-inbound-policy=all-authenticated
kubectl -n starfleet rollout restart deployment scout
kubectl -n starfleet rollout status deployment scout
```

Now send a request from both clients:

```sh
kubectl -n outpost exec deploy/drifter -- curl -s -w '\n%{http_code}\n' http://scout.starfleet
kubectl -n starfleet exec deploy/shuttle -c shuttle -- curl -s -o /dev/null -w '%{http_code}\n' http://scout.starfleet
```

You should see:

```text

403
200
```

`drifter` gets `403` with an empty body: `scout`'s proxy read the HTTP request, found no identity, and refused it. Unlike Istio's STRICT mode, the plain-text request is answered, not reset. `shuttle` has an identity and passes. Before the restart, `drifter` still got `200`, because the old proxy had read the old value when it started.

You now know that Linkerd encrypts meshed traffic without any setting, how to read a workload's identity, how to prove TLS with `viz edges` and `viz tap`, and how the default inbound policy decides what happens to callers no rule covers. Every meshed workload can still call `scout`, though. The open question is how to allow one identity and no other.

## Common pitfalls

> [!WARNING]
> - **Looking for a resource that turns on mTLS.** There is none; meshed pods always use mTLS with each other.
> - **Changing the default policy annotation and testing at once.** The proxy reads it at start; restart the workloads.
> - **Treating `all-authenticated` as "only my team".** It admits every meshed identity in the cluster. Use a Server and an AuthorizationPolicy for specific callers.
> - **Expecting `viz edges` to show unmeshed clients.** A client without a proxy never appears; use `viz tap` on the server to see its requests.
