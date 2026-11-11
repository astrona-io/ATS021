# Question

Solve this question on: `terminal`

The `scale-operator` service account has no resource permissions. It must change only the replica count of `starfleet/scout`, without permission to change the Deployment template.

## Tasks

1. Create a Role and RoleBinding allowing `get` on Deployment `scout` and `get` and `patch` on its `deployments/scale` subresource. Restrict both rules with `resourceNames`.

2. Prove that `kubectl scale deployment scout --replicas=2 --dry-run=server` succeeds when impersonating `scale-operator`.

3. Prove that scaling `probe` or `outpost/drifter`, patching the `scout` Deployment itself, creating or deleting Deployments, and reading Secrets remain denied.

Keep the prepared workloads, service accounts and namespace labels unchanged.

Learner work: about 15 minutes. Cluster startup and controller reconciliation take additional time.
