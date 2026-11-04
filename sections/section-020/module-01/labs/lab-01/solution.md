# Solution

Solve this lab on `terminal`. The output below comes from a real run of this lab.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-020/module-01/labs/lab-01
```

Keep this command running in a second host terminal. It grades the lab every few seconds and records nothing:

```sh
astrona submit --watch --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-020/module-01/labs/lab-01
```

Use `--watch` until the end, because a plain `astrona submit` finishes the attempt and deletes the lab. Run the plain command once, in the last step.

The watch terminal right after the start shows one check that already passes. `scout-allows-shuttle-get` passes because every caller may reach `scout`. It stays your guard: it fails if a policy blocks `shuttle`.

## Step 1: Require STRICT mTLS in starfleet

A request from `drifter` currently gets `200`, because the sidecars accept plain text in `PERMISSIVE` mode. Save this as `peerauthentication-starfleet-strict.yaml`:

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

Wait about ten seconds, then send a request from `drifter` (no sidecar) and from `shuttle` (sidecar):

```sh
kubectl -n outpost exec deploy/drifter -- curl -sS -o /dev/null -w '%{http_code}\n' http://scout.starfleet
kubectl -n starfleet exec deploy/shuttle -c shuttle -- curl -sS -o /dev/null -w '%{http_code}\n' http://probe.starfleet/get
```

You should see:

```text
curl: (56) Recv failure: Connection reset by peer
000
command terminated with exit code 56
200
```

The sidecar of `scout` expected a TLS handshake, got plain HTTP and closed the connection.

The watch terminal now shows the check `strict-mtls-required` passing. Do not use `PERMISSIVE` or `DISABLE`: both let `drifter` through.

## Step 2: Allow only GET from shuttle

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

Wait about ten seconds. Then send a `POST` from `shuttle` and a `GET` from `caller`:

```sh
kubectl -n starfleet exec deploy/shuttle -c shuttle -- curl -s -w '\n%{http_code}\n' -X POST http://scout.starfleet/echo -d hi
kubectl -n starfleet exec deploy/caller -c caller -- curl -s -w '\n%{http_code}\n' http://scout.starfleet/
```

You should see:

```text
RBAC: access denied
403
RBAC: access denied
403
```

Envoy in the sidecar of `scout` wrote this answer. The first ALLOW policy turned `scout` into an allow list: a request is allowed only if a rule matches. The watch terminal now shows the check `scout-refuses-other-callers` passing.

## Step 3: Deny the /env path

Save this as `authorizationpolicy-scout-deny-env.yaml`:

```yaml
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: scout-deny-env
  namespace: starfleet
spec:
  selector:
    matchLabels:
      app: scout
  action: DENY
  rules:
    - to:
        - operation:
            paths: ["/env"]
```

Apply it:

```sh
kubectl apply -f authorizationpolicy-scout-deny-env.yaml
```

You should see:

```text
Warning: configured AuthorizationPolicy will deny all traffic to TCP ports under its scope due to the use of only HTTP attributes in a DENY rule; it is recommended to explicitly specify the port
authorizationpolicy.security.istio.io/scout-deny-env created
```

The warning is safe here, because `scout` serves only HTTP. Wait about ten seconds, then check both paths from `shuttle`:

```sh
kubectl -n starfleet exec deploy/shuttle -c shuttle -- curl -s -o /dev/null -w '%{http_code}\n' http://scout.starfleet/env
kubectl -n starfleet exec deploy/shuttle -c shuttle -- curl -s -o /dev/null -w '%{http_code}\n' http://scout.starfleet/
```

You should see:

```text
403
200
```

The DENY policy is checked before the ALLOW policy, so `/env` is refused even for `shuttle`. List the policies the sidecar of `scout` uses:

```sh
istioctl x authz check deploy/scout -n starfleet
```

You should see:

```text
ACTION   AuthorizationPolicy             RULES
DENY     scout-deny-env.starfleet        1
ALLOW    _anonymous_match_nothing_       1
ALLOW    scout-allow-shuttle.starfleet   1
```

Press Ctrl-C to stop the watch, then run the grader once:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-020/module-01/labs/lab-01
```

You should see `4 passed, 0 failed` and `PROCTOR: PASS`.

Finally remove the lab:

```sh
astrona destroy ats-021-lab-020-01
```
