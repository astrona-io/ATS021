# Question

Solve this question on: `terminal`

The `legacy-agent` service account in `starfleet` is bound to `cluster-admin`. It needs only to read Pods in its own namespace.

## Tasks

1. Find the binding that grants `legacy-agent` cluster-wide administrator access.

2. Replace that grant with a Role and RoleBinding for `get`, `list` and `watch` on Pods in `starfleet`. Keep the service account.

3. Prove that Pod reads succeed while reading Secrets, deleting nodes and reading Pods in `outpost` are denied.

Keep the prepared workloads, service accounts and namespace labels unchanged.

Learner work: about 15 minutes. Cluster startup and controller reconciliation take additional time.
