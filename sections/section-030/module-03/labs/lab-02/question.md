# Question

Solve this question on: `terminal`

The enforcing `workload-check` policy in `starfleet` rejects compliant Deployments. One expression reads `replica` instead of `replicas`; another reads `labels.team` without checking whether the key exists. The same binding must continue enforcing both rules.

## Tasks

1. Inspect `status.typeChecking.expressionWarnings` and the rejection from a compliant server-side dry run. Identify the type error and the possible missing-key error.

2. Repair the policy so replicas may be at most five and the pod template must have a nonempty `team` label. Preserve the policy and binding names, `failurePolicy: Fail`, CREATE and UPDATE matching, and `validationActions: [Deny]`.

3. Prove that compliant objects are admitted, excessive replicas and absent or empty team labels are rejected with the intended messages, and `outpost` stays unaffected. Keep the messages `replicas must not exceed five` and `team must be nonempty`.

Keep the prepared workloads, service accounts and namespace labels unchanged.

Learner work: about 15 minutes. Cluster startup and controller reconciliation take additional time.
