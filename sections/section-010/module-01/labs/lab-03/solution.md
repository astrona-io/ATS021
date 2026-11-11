# Solution

Apply the configuration, then check both allowed and denied behavior.

Save this as `practice-solution.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: view-leases
  labels:
    rbac.authorization.k8s.io/aggregate-to-view: 'true'
rules:
- apiGroups:
  - coordination.k8s.io
  resources:
  - leases
  verbs:
  - get
  - list
  - watch
```

Apply it:

```sh
kubectl apply -f practice-solution.yaml
```

Check the result:

```sh
kubectl -n starfleet get leases --as=dev-anna --as-group=developers
kubectl auth can-i get secrets -n starfleet --as=dev-anna --as-group=developers
kubectl auth can-i list leases.coordination.k8s.io -n outpost --as=dev-anna --as-group=developers
```

Use the returned objects and decisions to check every task. A denied request must identify the expected access or policy restriction; a connection failure is not evidence that the restriction works.
