# Solution

Apply the configuration, then check both allowed and denied behavior.

Save this as `practice-solution.yaml`:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: allowed-registries
spec:
  background: true
  rules:
  - name: only-ghcr
    match:
      any:
      - resources:
          kinds:
          - Pod
          namespaceSelector:
            matchExpressions:
            - key: environment
              operator: Exists
    validate:
      failureAction: Enforce
      message: Images must come from ghcr.io.
      pattern:
        spec:
          containers:
          - image: ghcr.io/*
```

Apply it:

```sh
kubectl apply -f practice-solution.yaml
```

Check the result:

```sh
kubectl -n starfleet create deployment image-check --image=ghcr.io/stefanprodan/podinfo:6.15.0 --dry-run=server
kubectl -n starfleet-prod create deployment image-check --image=ghcr.io/stefanprodan/podinfo:6.15.0 --dry-run=server
kubectl -n default create deployment image-check --image=docker.io/library/nginx:latest --dry-run=server
```

Use the returned objects and decisions to check every task. A denied request must identify the expected access or policy restriction; a connection failure is not evidence that the restriction works.
