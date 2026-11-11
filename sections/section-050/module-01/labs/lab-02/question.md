# Question

Solve this question on: `terminal`

The compliance Task, conditional deploy and limited service account already work. The Pipeline has no finally Task. Prepared releases are `release-compliant`, `release-noncompliant` and `release-outpost` in `pipelines`.

## Tasks

1. Inspect the working `check` result and conditional `deploy` in `release-gate`. Keep them intact.

2. Add a finally Task named `report`, using `report-outcome`. Pass `$(tasks.status)` as `pipeline-status` and `$(tasks.check.status)` as `check-status`.

3. Run compliant, noncompliant and out-of-scope releases. Verify that `report` succeeds after a deployed release, a skipped deploy and a failed deploy.

Keep the supplied Tasks, ConfigMaps, workload identities and namespaces. Do not hard-code release decisions. Each run takes additional time; inspect its conditions and TaskRuns before judging the outcome.

Learner work: about 15 minutes. Cluster startup and controller reconciliation take additional time.
