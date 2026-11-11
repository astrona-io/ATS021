# Question

Solve this question on: `terminal`

Kyverno runs with an Audit-mode `allowed-registries` policy. `starfleet` has `environment: development`; `starfleet-prod` has `environment: production`. Other namespaces have no environment label.

## Tasks

1. Inspect `allowed-registries` and confirm that a foreign image is admitted before the repair.

2. Repair the policy so regular container images must start with `ghcr.io/` in every namespace with an `environment` label. Enforce the rule for Pods and generated Deployment rules.

3. Prove GHCR images are accepted, foreign and lookalike hosts are denied, and `default` stays unaffected. Keep namespace labels unchanged.

Keep the prepared workloads, service accounts and namespace labels unchanged.

Learner work: about 15 minutes. Cluster startup and controller reconciliation take additional time.
