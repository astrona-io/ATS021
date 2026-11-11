# Question

Solve this question on: `terminal`

Kyverno is ready and no policies exist. Require resource limits for new Pods and Deployment templates in `starfleet`.

## Tasks

1. Inspect the running workloads and confirm that a Pod without limits is currently admitted with a server-side dry run.

2. Write an enforcing ClusterPolicy requiring both CPU and memory limits on every regular container in `starfleet`.

3. Prove that missing either limit is rejected for Pods and Deployments, that both limits are accepted, and that `outpost` remains outside the rule.

Keep the prepared workloads, service accounts and namespace labels unchanged.

Learner work: about 15 minutes. Cluster startup and controller reconciliation take additional time.
