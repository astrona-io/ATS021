# Solution

Apply the configuration, then check both allowed and denied behavior.

Save this as `practice-solution.yaml`:

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
        principals:
        - cluster.local/ns/starfleet/sa/shuttle
    to:
    - operation:
        methods:
        - GET
---
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
        paths:
        - /env
```

Apply it:

```sh
kubectl apply -f practice-solution.yaml
```

Check the result:

```sh
kubectl -n starfleet exec deploy/shuttle -c shuttle -- curl -s -o /dev/null -w "%{http_code}\n" http://scout.starfleet/
kubectl -n starfleet exec deploy/caller -c caller -- curl -s -o /dev/null -w "%{http_code}\n" http://scout.starfleet/
kubectl -n starfleet exec deploy/shuttle -c shuttle -- curl -s -o /dev/null -w "%{http_code}\n" http://scout.starfleet/env
```

Use the returned objects and decisions to check every task. A denied request must identify the expected access or policy restriction; a connection failure is not evidence that the restriction works.
