# Finding Over-Broad Grants And Extending Roles

Least privilege is not only about the grants you write. Clusters collect grants over time: an agent installed years ago, a quick fix during an outage, a Helm chart that asked for `cluster-admin`. Each one is a service account token that can do anything if it leaks. This part searches the playground for the most dangerous kind of grant, removes it, and then adds rights to a built-in role in the one way that survives upgrades.

## Who has cluster-admin

`cluster-admin` allows every verb on every resource in every namespace. Start the search with the ClusterRoleBindings that point at it. `-o wide` adds the role and the subjects to the table:

<!-- astrona:playground:renew -->

```sh
kubectl get clusterrolebindings -o wide | grep -E '^NAME|cluster-admin'
```

You should see something like this (the wide columns are shortened):

```text
NAME                     ROLE                        AGE   USERS   GROUPS                   SERVICEACCOUNTS
cluster-admin            ClusterRole/cluster-admin   94s           system:masters           
kubeadm:cluster-admins   ClusterRole/cluster-admin   95s           kubeadm:cluster-admins   
legacy-agent-admin       ClusterRole/cluster-admin   73s                                    starfleet/legacy-agent
```

The first two are part of every kubeadm-built cluster, and `kind` is one. They give `cluster-admin` to the groups that the administrator certificates carry. The third gives it to the service account `legacy-agent` in `starfleet`. Any pod that runs as that service account, or anyone who gets its token, can read every Secret and delete every node.

`grep` on table output is fine for a first look, but it misses bindings whose role name is cut off or that use a different ClusterRole with the same power. `jq` reads the JSON and selects bindings by their `roleRef`:

```sh
kubectl get clusterrolebindings -o json | jq -r '.items[] | select(.roleRef.name=="cluster-admin") | .metadata.name + "  " + ([.subjects[]? | .kind + ":" + (.namespace // "") + "/" + .name] | join(", "))'
```

You should see:

```text
cluster-admin  Group:/system:masters
kubeadm:cluster-admins  Group:/kubeadm:cluster-admins
legacy-agent-admin  ServiceAccount:starfleet/legacy-agent
```

The output names each binding and each subject with its kind, so a service account stands out from a group.

## Everything one service account is bound to

Before you remove a grant, find every binding that names the identity, in every namespace. Otherwise you remove one grant and miss another. This search covers RoleBindings and ClusterRoleBindings at once:

```sh
kubectl get rolebindings,clusterrolebindings -A -o json | jq -r '.items[] | select(any(.subjects[]?; .kind=="ServiceAccount" and .name=="legacy-agent")) | .kind + " " + (.metadata.namespace // "-") + "/" + .metadata.name + " -> " + .roleRef.kind + "/" + .roleRef.name'
```

You should see:

```text
ClusterRoleBinding -/legacy-agent-admin -> ClusterRole/cluster-admin
```

One binding, and it is the over-broad one. Confirm what it allows today, then remove it:

```sh
kubectl auth can-i delete nodes --as=system:serviceaccount:starfleet:legacy-agent
kubectl delete clusterrolebinding legacy-agent-admin
kubectl auth can-i delete nodes --as=system:serviceaccount:starfleet:legacy-agent
```

You should see:

```text
Warning: resource 'nodes' is not namespace scoped

yes
clusterrolebinding.rbac.authorization.k8s.io "legacy-agent-admin" deleted
Warning: resource 'nodes' is not namespace scoped

no
```

The warning is `kubectl` telling you that it ignores the namespace for a cluster-wide resource; it is harmless. The answer changed from `yes` to `no`. On a real cluster, the next step is to find out what the agent actually needs and give it a Role with exactly that, the same way as for `ci-deployer`. Removing the binding first and watching which `Forbidden` errors the agent logs is a common way to find out.

## Extending a built-in role with aggregation

The developers can read pods, Services and most other namespaced objects with the `view` ClusterRole, but `view` does not include Leases. A Lease is a small object in the `coordination.k8s.io` group that controllers use to elect a leader and that nodes use to report that they are alive. You could edit `view`, but the API server owns it: it carries the annotation `rbac.authorization.kubernetes.io/autoupdate: "true"`, and the API server resets built-in roles to their defaults when it starts.

`view` is built in a different way, too. Look at the top of it:

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

You can now find every grant of `cluster-admin`, list every binding of one identity across the cluster, remove an over-broad grant and prove the result. You have also extended a built-in role through its aggregation label, which keeps working after the API server resets its defaults. Together with exact Roles and the right binding scope, that is least-privilege RBAC.

## Common pitfalls

> [!WARNING]
> - **Searching only ClusterRoleBindings.** A RoleBinding to `cluster-admin` gives full rights inside its namespace, including every Secret there. Search both kinds.
> - **Editing a built-in ClusterRole such as `view` or `edit`.** The API server resets it. Add a labelled ClusterRole instead.
> - **Labelling a broad role `aggregate-to-view`.** Every subject bound to `view` in every namespace gets its rules at once. Keep aggregated roles small and read-only for `view`.
> - **Removing a grant without checking what still needs it.** Watch for `Forbidden` errors from the workload afterwards and give it a precise Role.
