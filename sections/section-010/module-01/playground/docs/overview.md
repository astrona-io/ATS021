# Overview: Grant Least-Privilege Access With RBAC (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with the example workloads and a few service accounts, and then waits. There is no task, no `astrona submit` and no pass or fail. Write roles and bindings, break them, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already pointed at it, as the cluster administrator. Check other identities with `--as` and `--as-group`.
- The example workloads, each on a service account with its own name:

  | Namespace | Object | What it is |
  | --- | --- | --- |
  | `starfleet` | `scout`, `probe`, `shuttle` | The example application |
  | `outpost` | `drifter` | A client that belongs to another team |
  | `starfleet` | service account `ci-deployer` | A deploy pipeline's identity with no permissions |
  | `starfleet` | service account `legacy-agent` | Bound to `cluster-admin` by the ClusterRoleBinding `legacy-agent-admin`, on purpose |

- No `Role` or `RoleBinding` exists yet in `starfleet` or `outpost`.

## Helpers

Paste these once in each new terminal. `can_sa` checks one verb on one resource for a service account in `starfleet`. `bindings_of` lists every RoleBinding and ClusterRoleBinding that names a service account (it needs `jq`).

```sh
can_sa() {
  kubectl auth can-i "$2" "$3" -n "${4:-starfleet}" --as="system:serviceaccount:starfleet:$1"
}
bindings_of() {
  kubectl get rolebindings,clusterrolebindings -A -o json | jq -r --arg sa "$1" \
    '.items[] | select(any(.subjects[]?; .kind=="ServiceAccount" and .name==$sa)) | .kind + " " + (.metadata.namespace // "-") + "/" + .metadata.name + " -> " + .roleRef.kind + "/" + .roleRef.name'
}
```

Use them like this: `can_sa ci-deployer create deployments`, `can_sa ci-deployer list pods outpost`, `bindings_of legacy-agent`.

## Practice tasks

- Give `ci-deployer` exactly what `kubectl apply` and `kubectl rollout status` need for one Deployment, and nothing else. Prove each verb with `can-i` before you test it for real.
- Bind the `edit` ClusterRole to the group `developers` in `outpost` only, then predict the answer of `can-i delete pods -n starfleet` for `dev-anna` in that group before you run it.
- Find every identity that can read Secrets in `starfleet`. Use `kubectl auth can-i --list --as=...` for the identities you know about, and the bindings for the ones you do not.
- Remove the `legacy-agent-admin` binding and give `legacy-agent` a Role that only lets it read ConfigMaps in `starfleet`.
- Create a small ClusterRole with the label `rbac.authorization.k8s.io/aggregate-to-edit: "true"` and check whether `view` gains its rules, or only `edit` and `admin`.
