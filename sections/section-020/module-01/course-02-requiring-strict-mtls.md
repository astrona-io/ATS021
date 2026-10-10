# Requiring STRICT Mutual TLS

PERMISSIVE mode is a migration aid, not a security setting. As long as a sidecar accepts plain text, any pod in the cluster can call the workload without a certificate, and nothing in the request proves who sent it. This part turns on STRICT mode for `starfleet`, proves that a plain-text client is refused, and finds the kind of workload that breaks when you do it.

## PeerAuthentication

A **PeerAuthentication** is the Istio resource that sets whether a workload's sidecar accepts plain-text traffic (`PERMISSIVE`) or only mTLS (`STRICT`). It has three scopes, and the most specific one wins:

- **Mesh-wide**: a PeerAuthentication in Istio's root namespace, `istio-system`, without a `selector`.
- **Namespace-wide**: a PeerAuthentication in the namespace without a `selector`. By convention it is named `default`.
- **Workload**: a PeerAuthentication with a `selector` that matches pod labels. It can also set a different mode per port with `portLevelMtls`.

Require mTLS for the whole `starfleet` namespace.

<!-- astrona:playground:renew -->

Save this as `peerauthentication-starfleet-strict.yaml`:

```yaml
apiVersion: security.istio.io/v1
kind: PeerAuthentication
metadata:
  name: default
  namespace: starfleet
spec:
  mtls:
    mode: STRICT
```

Apply it:

```sh
kubectl apply -f peerauthentication-starfleet-strict.yaml
```

`istiod` sends the new setting to every sidecar in `starfleet` within a few seconds. If a check below still shows the old result, wait a few seconds and run it again.

## Prove it from both sides

Send the same request from `drifter`, which has no sidecar, and from `shuttle`, which has one:

```sh
kubectl -n outpost exec deploy/drifter -- curl -sS -o /dev/null -w '%{http_code}\n' http://scout.starfleet
kubectl -n starfleet exec deploy/shuttle -c shuttle -- curl -sS -o /dev/null -w '%{http_code}\n' http://scout.starfleet
```

You should see:

```text
000
curl: (56) Recv failure: Connection reset by peer
command terminated with exit code 56
200
```

`drifter`'s request never got an HTTP answer. `scout`'s sidecar expected a TLS handshake, received plain HTTP, and closed the connection, which `curl` reports as `Connection reset by peer` and the status `000`. There is no `403`, because the request never got far enough to be read. `shuttle`'s sidecar uses mTLS automatically, so its request still returns `200`. Istio's clients pick mTLS on their own whenever the server has a sidecar; you do not configure the client side.

`istioctl x describe pod` now names the policy that applies:

```sh
istioctl x describe pod $(kubectl -n starfleet get pod -l app=scout -o jsonpath='{.items[0].metadata.name}') -n starfleet | grep -A3 Effective
```

You should see:

```text
Effective PeerAuthentication:
   Workload mTLS mode: STRICT
Applied PeerAuthentication:
   default.starfleet
```

## The workload without a sidecar

STRICT only works when every caller inside the namespace has a sidecar too. A pod can opt out of injection with the label `sidecar.istio.io/inject: "false"`, and teams sometimes add it to fix an unrelated problem and forget it. Add such a workload: `beacon`, a client that runs on the `shuttle` service account but without a sidecar.

Save this as `deployment-beacon.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: beacon
  namespace: starfleet
  labels:
    app: beacon
spec:
  replicas: 1
  selector:
    matchLabels:
      app: beacon
  template:
    metadata:
      labels:
        app: beacon
        sidecar.istio.io/inject: "false"
    spec:
      serviceAccountName: shuttle
      containers:
        - name: beacon
          image: curlimages/curl:8.22.0
          command: ["sh", "-c", "while true; do sleep 30; done"]
```

Apply it and send a request from it:

```sh
kubectl apply -f deployment-beacon.yaml
kubectl -n starfleet rollout status deployment beacon
kubectl -n starfleet exec deploy/beacon -- curl -sS -o /dev/null -w '%{http_code}\n' http://scout.starfleet
```

You should see something like:

```text
deployment.apps/beacon created
deployment "beacon" successfully rolled out
curl: (56) Recv failure: Connection reset by peer
000
command terminated with exit code 56
```

`beacon` is in the same namespace and uses the same service account as `shuttle`, and it still fails. Without a sidecar it has no certificate, so it has no identity at all. A service account only becomes a mesh identity through the sidecar.

To find such workloads, look for pods without the `istio-proxy` container:

```sh
kubectl -n starfleet get pods -o custom-columns='NAME:.metadata.name,SIDECAR:.spec.initContainers[?(@.name=="istio-proxy")].name'
```

You should see something like:

```text
NAME                       SIDECAR
beacon-db8746658-vjltt     <none>
probe-6f569ff97-qdzc5      istio-proxy
scout-64445474d5-gvvck     istio-proxy
shuttle-75fc875874-bkkrh   istio-proxy
```

`istioctl x check-inject` then says why a workload was not injected:

```sh
istioctl x check-inject -n starfleet deploy/beacon
```

You should see something like (the colour marks are shown as `✘`):

```text
WEBHOOK                     REVISION  INJECTED      REASON
istio-revision-tag-default  default   ✘             Pod has sidecar.istio.io/inject=false label, preventing injection
istio-sidecar-injector      default   ✘             The injection webhook is deactivated, and will never match labels.
```

The first line is the reason. The fix is to remove the label from the pod template, so the next pods get a sidecar. Deleting the PeerAuthentication or switching it back to `PERMISSIVE` would also make `beacon` work, but it would open the namespace to every plain-text client again.

You can now require mTLS for a namespace with a PeerAuthentication, prove it with a plain-text client that is refused and a mesh client that is not, and find workloads that lost their sidecar. Every caller to `starfleet` now has a verified identity. The open question is what those identities may do: so far, every workload with a sidecar may still call `scout` with any request.

## Common pitfalls

> [!WARNING]
> - **Expecting a `403` from STRICT.** A plain-text client gets a reset connection (`curl` exit code `56`), not an HTTP status.
> - **Turning on STRICT before every client has a sidecar.** Check for pods without `istio-proxy` first; PERMISSIVE is the migration step.
> - **Fixing a broken client by going back to PERMISSIVE.** That reopens the namespace to plain text. Give the client a sidecar.
> - **Putting a mesh-wide PeerAuthentication in the wrong namespace.** Mesh-wide means Istio's root namespace, `istio-system` by default.
