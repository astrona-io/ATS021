# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. The output below comes from a real run of this lab.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-020/module-02/labs/lab-01
```

`astrona submit` right after the start shows one check that already passes. `probe-serves-meshed-callers` passes because every caller may reach `probe`. It stays your guard: it fails if a policy locks `probe` for everyone.

## Step 1: Allow only shuttle to call scout

Three resources do this. A `Server` selects the `http` port of `scout`, a `MeshTLSAuthentication` names the `shuttle` service account, and an `AuthorizationPolicy` connects the two. Save this as `server-scout-http.yaml`:

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
```

Save this as `meshtlsauthentication-shuttle.yaml`:

```yaml
apiVersion: policy.linkerd.io/v1alpha1
kind: MeshTLSAuthentication
metadata:
  name: shuttle
  namespace: starfleet
spec:
  identityRefs:
    - kind: ServiceAccount
      name: shuttle
```

Save this as `authorizationpolicy-scout-allow-shuttle.yaml`:

```yaml
apiVersion: policy.linkerd.io/v1alpha1
kind: AuthorizationPolicy
metadata:
  name: scout-allow-shuttle
  namespace: starfleet
spec:
  targetRef:
    group: policy.linkerd.io
    kind: Server
    name: scout-http
  requiredAuthenticationRefs:
    - group: policy.linkerd.io
      kind: MeshTLSAuthentication
      name: shuttle
```

Apply all three:

```sh
kubectl apply -f server-scout-http.yaml -f meshtlsauthentication-shuttle.yaml -f authorizationpolicy-scout-allow-shuttle.yaml
```

You should see:

```text
server.policy.linkerd.io/scout-http created
meshtlsauthentication.policy.linkerd.io/shuttle created
authorizationpolicy.policy.linkerd.io/scout-allow-shuttle created
```

Wait about ten seconds, then send a request from each of the three callers:

```sh
kubectl -n starfleet exec deploy/shuttle -c shuttle -- curl -s -o /dev/null -w '%{http_code}\n' http://scout.starfleet
kubectl -n outpost exec deploy/drifter -c drifter -- curl -s -o /dev/null -w '%{http_code}\n' http://scout.starfleet
kubectl -n starfleet exec deploy/caller -c caller -- curl -s -o /dev/null -w '%{http_code}\n' http://scout.starfleet
```

You should see:

```text
200
403
403
```

Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-020/module-02/labs/lab-01 --keep
```

The check `scout-allows-only-shuttle` now passes.

## Step 2: Refuse callers without a proxy on probe

Do not give `probe` a Server. Set the default inbound policy of the namespace to `all-authenticated`, which admits only callers with a valid mesh identity:

```sh
kubectl annotate namespace starfleet config.linkerd.io/default-inbound-policy=all-authenticated
```

You should see:

```text
namespace/starfleet annotated
```

A proxy reads this value when it starts, so restart `probe`:

```sh
kubectl -n starfleet rollout restart deployment probe
kubectl -n starfleet rollout status deployment probe
```

Wait a few seconds, then send a request from `drifter`, `shuttle` and `caller`:

```sh
kubectl -n outpost exec deploy/drifter -c drifter -- curl -s -w '\n%{http_code}\n' --max-time 10 http://probe.starfleet/get
kubectl -n starfleet exec deploy/shuttle -c shuttle -- curl -s -o /dev/null -w '%{http_code}\n' http://probe.starfleet/get
kubectl -n starfleet exec deploy/caller -c caller -- curl -s -o /dev/null -w '%{http_code}\n' http://probe.starfleet/get
```

You should see:

```text

403
200
200
```

The first line is the empty body of the `403` from `drifter`. If the first request times out right after the restart, run it again. The `scout` Server from step 1 still decides who reaches `scout`, because a Server replaces the default for its port.

Run the grader one last time without `--keep`:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-020/module-02/labs/lab-01
```

You should see `3 passed, 0 failed` and `PROCTOR: PASS`.

Finally remove the lab:

```sh
astrona destroy ats-021-lab-020-02
```
