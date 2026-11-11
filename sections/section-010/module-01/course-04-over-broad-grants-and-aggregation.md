# Find And Remove Over-Broad Grants

A service account can receive rights from several bindings. Removing one broad grant does not prove the account now has only the intended permissions. Inspect all bindings, replace excessive access with a precise Role, and check the resulting scope.

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

After replacing a grant, prove that required reads still work and that unrelated writes, Secrets and other namespaces stay outside the account’s permissions.

## Common pitfalls

> [!WARNING]
> - Search RoleBindings and ClusterRoleBindings for the identity.
> - Check the service account namespace as well as its name.
> - Keep the workload’s required access when removing its broad binding.
