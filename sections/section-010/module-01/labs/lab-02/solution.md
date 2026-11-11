# Solution

Apply the configuration, then check both allowed and denied behavior.

Save this as `practice-solution.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader
  namespace: starfleet
rules:
- apiGroups:
  - ''
  resources:
  - pods
  verbs:
  - get
  - list
  - watch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: legacy-agent-pod-reader
  namespace: starfleet
subjects:
- kind: ServiceAccount
  name: legacy-agent
  namespace: starfleet
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pod-reader
```

Apply it:

```sh
kubectl apply -f practice-solution.yaml
```

Complete the change:

```sh
kubectl delete clusterrolebinding legacy-agent-admin
```

Check the result:

```sh
kubectl -n starfleet get pods --as=system:serviceaccount:starfleet:legacy-agent
kubectl auth can-i get secrets -n starfleet --as=system:serviceaccount:starfleet:legacy-agent
kubectl auth can-i list pods -n outpost --as=system:serviceaccount:starfleet:legacy-agent
```

Use the returned objects and decisions to check every task. A denied request must identify the expected access or policy restriction; a connection failure is not evidence that the restriction works.
