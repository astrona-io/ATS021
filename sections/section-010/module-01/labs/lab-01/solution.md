# Solution

Apply the configuration, then check both allowed and denied behavior.

Save this as `practice-solution.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: deployment-manager
  namespace: starfleet
rules:
- apiGroups:
  - apps
  resources:
  - deployments
  verbs:
  - get
  - list
  - watch
  - create
  - update
  - patch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ci-deployer-deployment-manager
  namespace: starfleet
subjects:
- kind: ServiceAccount
  name: ci-deployer
  namespace: starfleet
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: deployment-manager
```

Apply it:

```sh
kubectl apply -f practice-solution.yaml
```

Check the result:

```sh
kubectl -n starfleet annotate deployment scout practice=checked --overwrite --as=system:serviceaccount:starfleet:ci-deployer
kubectl auth can-i delete deployments.apps -n starfleet --as=system:serviceaccount:starfleet:ci-deployer
kubectl auth can-i list deployments.apps -n outpost --as=system:serviceaccount:starfleet:ci-deployer
```

Use the returned objects and decisions to check every task. A denied request must identify the expected access or policy restriction; a connection failure is not evidence that the restriction works.
