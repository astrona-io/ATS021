# Question

Solve this question on: `terminal`

The `starfleet` namespace is running. A security review found three access problems. Fix all three with RBAC. Use only Roles and RoleBindings in `starfleet`, plus the one labelled ClusterRole in task 3. Do not change the workloads.

1. The service account `ci-deployer` in `starfleet` has no rights. It must be able to read (`get`, `list`, `watch`), create, `update` and `patch` Deployments in `starfleet`. It must not be able to delete Deployments, read Secrets, create pods, or do anything in another namespace.

2. The service account `legacy-agent` in `starfleet` is bound to the `cluster-admin` ClusterRole. Remove that grant, but keep the service account. The agent still has to read pods (`get`, `list`, `watch`) in `starfleet`, and nothing else.

3. The group `developers` already has the built-in `view` ClusterRole in `starfleet` through the RoleBinding `developers-view`. The group must also be able to list Leases (API group `coordination.k8s.io`) in `starfleet`. Do not edit the `view` ClusterRole and do not create a new binding. Extend `view` through its aggregation label instead.

`kubectl` already points at the cluster as the cluster administrator. You can check any identity with `--as` and `--as-group`.
