# Solution

The main Deployment and its scale subresource have separate rules. The read permission lets the client inspect the named object; the scale permission permits a replica change without granting a template change.

Save this as `practice-solution.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: scout-scaler
  namespace: starfleet
rules:
- apiGroups:
  - apps
  resources:
  - deployments
  resourceNames:
  - scout
  verbs:
  - get
- apiGroups:
  - apps
  resources:
  - deployments/scale
  resourceNames:
  - scout
  verbs:
  - get
  - patch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: scout-scaler
  namespace: starfleet
subjects:
- kind: ServiceAccount
  name: scale-operator
  namespace: starfleet
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: scout-scaler
```

Apply it:

```sh
kubectl apply -f practice-solution.yaml
```

Check the result:

```sh
kubectl -n starfleet scale deployment scout --replicas=2 --dry-run=server --as=system:serviceaccount:starfleet:scale-operator
kubectl auth can-i patch deployments/scout --subresource=scale -n starfleet --as=system:serviceaccount:starfleet:scale-operator
kubectl auth can-i patch deployments/scout -n starfleet --as=system:serviceaccount:starfleet:scale-operator
```

Use the returned objects and decisions to check every task. A denied request must identify the expected access or policy restriction; a connection failure is not evidence that the restriction works.
