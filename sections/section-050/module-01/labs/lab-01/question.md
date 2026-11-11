# Question

Solve this question on: `terminal`

Tekton, `deploy-release`, the policy and release ConfigMaps are ready. `pipeline-runner` already has limited deployment access. The Pipeline has no check Task and does not gate deployment.

## Tasks

1. Create `check-release` with workspaces `release` and `policies` and result `outcome`. Run the supplied policy through Kyverno CLI v1.19.1. Publish exactly `pass` or `fail` without a newline; the Task must succeed for either policy decision.

2. Add a `when` expression to Pipeline Task `deploy` in `release-gate`, using the result of Pipeline Task `check`. Deploy only when its value is `pass`.

3. Run the prepared compliant and noncompliant releases. Verify the check result, the deployed object for the compliant release, and a skipped deploy with no deploy TaskRun for the noncompliant release.

Keep the supplied Tasks, ConfigMaps, workload identities and namespaces. Do not hard-code release decisions. Each run takes additional time; inspect its conditions and TaskRuns before judging the outcome.

Learner work: about 15 minutes. Cluster startup and controller reconciliation take additional time.
