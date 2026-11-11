# Solution

Apply the configuration, then check both allowed and denied behavior.

Save this as `practice-solution.yaml`:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: image-tags
spec:
  background: true
  rules:
  - name: require-tag
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
      message: An image tag is required.
      pattern:
        spec:
          containers:
          - image: '*:*'
  - name: disallow-latest
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
      message: Using a mutable image tag such as 'latest' is not allowed.
      pattern:
        spec:
          containers:
          - image: '!*:latest'
---
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-digest
spec:
  background: true
  rules:
  - name: pin-by-digest
    match:
      any:
      - resources:
          kinds:
          - Pod
          namespaceSelector:
            matchLabels:
              environment: production
    validate:
      failureAction: Enforce
      message: Images in production must be pinned by digest (image@sha256:...).
      pattern:
        spec:
          containers:
          - image: '*@sha256:*'
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
