# Solution

Solve this lab on `terminal`. The output below comes from a real run of this lab.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-020/capstone/labs/lab-01
```

Keep this command running in a second host terminal. It grades the lab every few seconds and records nothing:

```sh
astrona submit --watch --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-020/capstone/labs/lab-01
```

Use `--watch` until the end, because a plain `astrona submit` finishes the attempt and deletes the lab. Run the plain command once, in the last step.

The watch terminal right after the start shows that no check passes: the mesh is in `PERMISSIVE` mode and no policy exists.

## Step 1: Require STRICT mTLS in starfleet

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

Wait about ten seconds. Then send a request from `drifter-plain` (no sidecar) and from `beacon`:

```sh
kubectl -n outpost exec deploy/drifter-plain -- curl -sS -o /dev/null -w '%{http_code}\n' http://scout.starfleet
kubectl -n starfleet exec deploy/beacon -- curl -sS -o /dev/null -w '%{http_code}\n' http://scout.starfleet
```

You should see:

```text
curl: (56) Recv failure: Connection reset by peer
000
command terminated with exit code 56
curl: (56) Recv failure: Connection reset by peer
000
command terminated with exit code 56
```

`beacon` is in `starfleet`, but it fails too. List the pods that have no sidecar:

```sh
kubectl -n starfleet get pods -o custom-columns='NAME:.metadata.name,SIDECAR:.spec.initContainers[?(@.name=="istio-proxy")].name'
```

You should see:

```text
NAME                       SIDECAR
beacon-f8f44fcf4-2ssxw     <none>
caller-7dc6cf69b8-v742k    istio-proxy
probe-6f569ff97-zm4wr      istio-proxy
scout-64445474d5-k5xsm     istio-proxy
shuttle-75fc875874-6wptr   istio-proxy
```

The watch terminal now shows the check `strict-mtls-required` passing. Do not use `PERMISSIVE` or `DISABLE`: both let `drifter-plain` through.

## Step 2: Allow only GET from shuttle to scout

Save this as `authorizationpolicy-scout-allow-shuttle.yaml`:

```yaml
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: scout-allow-shuttle
  namespace: starfleet
spec:
  selector:
    matchLabels:
      app: scout
  action: ALLOW
  rules:
    - from:
        - source:
            principals: ["cluster.local/ns/starfleet/sa/shuttle"]
      to:
        - operation:
            methods: ["GET"]
```

Apply it:

```sh
kubectl apply -f authorizationpolicy-scout-allow-shuttle.yaml
```

Wait about ten seconds. Then send a `POST` from `shuttle`, and a `GET` from `caller` and from `drifter`:

```sh
kubectl -n starfleet exec deploy/shuttle -c shuttle -- curl -s -o /dev/null -w '%{http_code}\n' -X POST -d hi http://scout.starfleet/echo
kubectl -n starfleet exec deploy/caller -c caller -- curl -s -o /dev/null -w '%{http_code}\n' http://scout.starfleet/
kubectl -n outpost exec deploy/drifter -c drifter -- curl -s -o /dev/null -w '%{http_code}\n' http://scout.starfleet/
```

You should see:

```text
403
403
403
```

If `caller` or `drifter` still shows `200`, the sidecar has not received the policy yet: run the command again after a few seconds. The `403` body is `RBAC: access denied`, written by Envoy in the sidecar of `scout`. Both `caller` and `drifter` use mTLS, so a missing certificate is not the reason: the policy names only the `shuttle` identity.

## Step 3: Make probe reachable only from starfleet

`drifter` has a sidecar, so STRICT mTLS does not stop it. Check:

```sh
kubectl -n outpost exec deploy/drifter -c drifter -- curl -sS -o /dev/null -w '%{http_code}\n' http://probe.starfleet/get
```

It prints `200`. An `AuthorizationPolicy` can allow a whole namespace with `source.namespaces`. Save this as `authorizationpolicy-probe-allow-starfleet.yaml`:

```yaml
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: probe-allow-starfleet
  namespace: starfleet
spec:
  selector:
    matchLabels:
      app: probe
  action: ALLOW
  rules:
    - from:
        - source:
            namespaces: ["starfleet"]
```

Apply it:

```sh
kubectl apply -f authorizationpolicy-probe-allow-starfleet.yaml
```

Wait about ten seconds. Then send a request from `drifter`, `caller` and `shuttle`:

```sh
kubectl -n outpost exec deploy/drifter -c drifter -- curl -s -o /dev/null -w '%{http_code}\n' http://probe.starfleet/get
kubectl -n starfleet exec deploy/caller -c caller -- curl -s -o /dev/null -w '%{http_code}\n' http://probe.starfleet/get
kubectl -n starfleet exec deploy/shuttle -c shuttle -- curl -s -o /dev/null -w '%{http_code}\n' http://probe.starfleet/get
```

You should see:

```text
403
200
200
```

The watch terminal now shows the checks `scout-allows-only-shuttle-get` and `probe-only-from-starfleet` passing.

## Step 4: Give beacon a sidecar

`beacon` has the label `sidecar.istio.io/inject: "false"` in its pod template. Show it:

```sh
kubectl -n starfleet get deployment beacon -o jsonpath='{.spec.template.metadata.labels}{"\n"}'
```

You should see:

```text
{"app":"beacon","sidecar.istio.io/inject":"false"}
```

Remove the label from the pod template. The Deployment then starts a new pod, and the Istio webhook adds the sidecar to it. Going back to `PERMISSIVE` would also make `beacon` work, but it would open the namespace again. The `~1` in the path stands for the `/` in the label name:

```sh
kubectl -n starfleet patch deployment beacon --type=json -p='[{"op":"remove","path":"/spec/template/metadata/labels/sidecar.istio.io~1inject"}]'
kubectl -n starfleet rollout status deployment beacon
kubectl -n starfleet exec deploy/beacon -c beacon -- curl -s -o /dev/null -w '%{http_code}\n' http://scout.starfleet/
```

You should see:

```text
deployment.apps/beacon patched
deployment "beacon" successfully rolled out
200
```

`beacon` runs as the `shuttle` service account, so with a sidecar it has the `shuttle` identity and the `GET` is allowed. Press Ctrl-C to stop the watch, then run the grader once:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-020/capstone/labs/lab-01
```

You should see `4 passed, 0 failed` and `PROCTOR: PASS`.

Finally remove the lab:

```sh
astrona destroy ats-021-capstone-020
```
