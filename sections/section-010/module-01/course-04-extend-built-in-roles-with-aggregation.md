# Extend Built-In Roles With Aggregation

The group `developers` can read workloads through the built-in `view` ClusterRole, but needs one additional read permission. An aggregated ClusterRole lets the control-plane controller extend `view` from labelled rules. The playground already has the `developers-view` RoleBinding in `starfleet`.

## Extending a built-in role with aggregation

The developers can read pods, Services and most other namespaced objects with the `view` ClusterRole, but `view` does not include Leases. A Lease is a small object in the `coordination.k8s.io` group that controllers use to elect a leader and that nodes use to report that they are alive. You could edit `view`, but the API server owns it: it carries the annotation `rbac.authorization.kubernetes.io/autoupdate: "true"`, and the API server resets built-in roles to their defaults when it starts.

`view` is built in a different way, too. Look at the top of it:

<!-- astrona:playground:renew -->

```sh
kubectl get clusterrole view -o yaml | head -20
```

You should see something like (shortened):

```text
aggregationRule:
  clusterRoleSelectors:
  - matchLabels:
      rbac.authorization.k8s.io/aggregate-to-view: "true"
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  ...
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
    rbac.authorization.k8s.io/aggregate-to-edit: "true"
  name: view
```

`aggregationRule` makes `view` an **aggregated ClusterRole**. A controller in the control plane fills its `rules` with the rules of every ClusterRole that carries the label `rbac.authorization.k8s.io/aggregate-to-view: "true"`, and keeps them in sync. So the safe way to extend `view` is to create a small ClusterRole with that label. `view` itself also carries `aggregate-to-edit`, so whatever `view` gains, `edit` gains too.

Check the starting point:

```sh
kubectl auth can-i list leases.coordination.k8s.io -n starfleet --as=dev-anna --as-group=developers
```

You should see:

```text
no
```

Save this as `clusterrole-view-leases.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: view-leases
  labels:
    rbac.authorization.k8s.io/aggregate-to-view: "true"
rules:
  - apiGroups: ["coordination.k8s.io"]
    resources: ["leases"]
    verbs: ["get", "list", "watch"]
```

Apply it and check again:

```sh
kubectl apply -f clusterrole-view-leases.yaml
kubectl auth can-i list leases.coordination.k8s.io -n starfleet --as=dev-anna --as-group=developers
kubectl -n starfleet get leases --as=dev-anna --as-group=developers
```

You should see:

```text
clusterrole.rbac.authorization.k8s.io/view-leases created
yes
No resources found in starfleet namespace.
```

The answer changed to `yes`, and the list request is now allowed; `starfleet` simply has no Leases yet. Run `kubectl get clusterrole view -o yaml` again: it now holds a `leases` rule that you never wrote into `view`. Nobody had to create a new binding, because the `developers-view` RoleBinding already points at `view`.

The aggregation controller combines the labelled rules into `view`; the existing RoleBinding still determines where the developers can use them.

## Common pitfalls

> [!WARNING]
> - Do not edit the rules of the built-in aggregated role directly.
> - A broad rule labelled for aggregation affects every subject bound to the target role.
> - Wait for the controller to update the aggregated rules before checking access.
