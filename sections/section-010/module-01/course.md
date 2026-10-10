# Grant Least-Privilege Access With RBAC

Every request to a Kubernetes cluster goes to the API server, and the API server asks one question before it does anything: is this identity allowed to do this? On almost every cluster, RBAC answers that question. RBAC (role-based access control) allows or denies each request by matching the identity against the rules of the roles bound to it. If RBAC is too strict, a deploy pipeline fails with `Forbidden`. If it is too loose, one stolen service account token can read every Secret in the cluster.

Keep one sentence in mind for this module: **a role says what may be done, a binding says who may do it, and the binding's kind and namespace say where.** You will give a pipeline's service account exactly the rights it needs, prove every answer with `kubectl auth can-i`, read the `Forbidden` errors that tell you what is missing, and find a grant that gives far too much.

The module has four parts. **The Request Path And Role Rules** follows one request through authentication, authorization and admission, and writes the first `Role` and `RoleBinding`. **Bindings, Subjects And Scope** compares users, groups and service accounts as subjects, and `Role` with `ClusterRole`. **Proving And Debugging Access** checks permissions for any identity and reads a `Forbidden` error field by field. **Finding Over-Broad Grants And Extending Roles** searches the cluster for `cluster-admin` bindings, removes one, and adds rights to a built-in role the safe way.

## Learning objectives

After this module you can:

- Create a `Role` and `RoleBinding` that give a service account exactly the verbs it needs on one resource in one namespace.
- Choose between `Role` and `ClusterRole`, and between `RoleBinding` and `ClusterRoleBinding`, for a given access requirement.
- Check any permission for another identity with `kubectl auth can-i --as`, including `--list`.
- Read a `Forbidden` error and name the missing verb, resource and API group.
- Find and remove an over-broad binding, such as `cluster-admin` given to a workload service account.
- Extend a `ClusterRole` through aggregation labels instead of editing a built-in role.

## Before you start

You need Kubernetes basics: namespaces, Deployments, Services, pods, and the commands `kubectl get`, `kubectl apply` and `kubectl delete`. You also need `jq` on your machine for one search in the last part.

Your playground is a single-node `kind` cluster running Kubernetes 1.35, with no extra tools. It has the following workloads and identities. A **service account** is the identity a pod uses when it calls the Kubernetes API; each workload here has its own:

| Namespace | Object | What it is |
| --- | --- | --- |
| `starfleet` | `scout`, `probe`, `shuttle` | The example application, each running on a service account of the same name |
| `outpost` | `drifter` | A client that belongs to another team |
| `starfleet` | service account `ci-deployer` | A deploy pipeline's identity. It has no permissions yet; you give it some |
| `starfleet` | service account `legacy-agent` | An old agent's identity, bound to `cluster-admin` by a `ClusterRoleBinding`. This over-broad grant is there on purpose |

No `Role` or `RoleBinding` exists yet in `starfleet` or `outpost`. You run every command as the cluster administrator, and you check other identities with `--as`. `kubectl` already points at the playground cluster.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
