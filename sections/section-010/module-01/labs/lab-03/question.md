# Question

Solve this question on: `terminal`

The group `developers` already has the built-in `view` ClusterRole in `starfleet` through `developers-view`. It cannot read Leases.

## Tasks

1. Inspect the existing binding and the aggregation selector of `view`.

2. Create a ClusterRole with `get`, `list` and `watch` on `leases` in `coordination.k8s.io`, labelled `rbac.authorization.k8s.io/aggregate-to-view: "true"`. Do not edit `view` or create another binding.

3. Wait for aggregation, then prove the group can list Leases in `starfleet` while Secret reads and Lease access in `outpost` stay denied.

Keep the prepared workloads, service accounts and namespace labels unchanged.

Learner work: about 15 minutes. Cluster startup and controller reconciliation take additional time.
