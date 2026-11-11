# Question

Solve this question on: `terminal`

The `ci-deployer` service account in `starfleet` has no resource permissions. Give this deployment pipeline access to one namespace.

## Tasks

1. Inspect the existing service account and confirm it cannot patch Deployments in `starfleet`.

2. Create a Role and RoleBinding allowing `get`, `list`, `watch`, `create`, `update` and `patch` on Deployments in `starfleet`.

3. Prove that the account can annotate `scout`, but cannot delete Deployments, read Secrets, create Pods or access Deployments in `outpost`.

Keep the prepared workloads, service accounts and namespace labels unchanged.

Learner work: about 15 minutes. Cluster startup and controller reconciliation take additional time.
