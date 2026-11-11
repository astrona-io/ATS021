# Question

Solve this question on: `terminal`

Kyverno is ready without policies. New Pods in `starfleet` need a default `team` label, while an explicitly supplied label must survive admission.

## Tasks

1. Create a ClusterPolicy mutate rule that adds `team: unassigned` only when the label is absent.

2. Use server-side dry runs to prove that an unlabelled Pod receives the default and a Pod with `team: blue` keeps its value.

3. Prove that an equivalent Pod in `outpost` stays unlabelled. Keep mutation scoped to `starfleet`.

Keep the prepared workloads, service accounts and namespace labels unchanged.

Learner work: about 15 minutes. Cluster startup and controller reconciliation take additional time.
