# Question

Solve this question on: `terminal`

The Pipeline already checks compliance, gates deployment and reports the outcome. Its `pipeline-runner` identity has a ClusterRoleBinding to `edit`, so it can deploy into unrelated namespaces.

## Tasks

1. Inspect the permissions and bindings of `pipelines/pipeline-runner`. Find its excessive cluster-wide grant.

2. Replace that grant with a Role and RoleBinding allowing only `get`, `list`, `create` and `patch` on Deployments in `starfleet`. Keep the service account and the working Pipeline unchanged.

3. Run `release-compliant` and `release-outpost`. The first must deploy; the second must fail at deploy with Forbidden. Prove that deleting Deployments and reading Secrets are denied.

Keep the supplied Tasks, ConfigMaps, workload identities and namespaces. Do not hard-code release decisions. Each run takes additional time; inspect its conditions and TaskRuns before judging the outcome.

Learner work: about 15 minutes. Cluster startup and controller reconciliation take additional time.
