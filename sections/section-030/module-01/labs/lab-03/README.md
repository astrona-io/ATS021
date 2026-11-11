---
estimated_duration: 15m
---

# Default Pod Labels With A Mutate Rule

Kyverno is ready without policies. New Pods in `starfleet` need a default `team` label, while an explicitly supplied label must survive admission.

Allow about 15 minutes of learner work, plus startup and reconciliation.

```sh
astrona run -c sections/section-030/module-01/labs/lab-03
astrona submit -c sections/section-030/module-01/labs/lab-03
astrona destroy ats-021-lab-030-01-03
```

The task is in [question.md](question.md), with a [reference walkthrough](solution.md). Authors run `astrona validate -c sections/section-030/module-01/labs/lab-03` and `astrona test -c sections/section-030/module-01/labs/lab-03`. The lifecycle checks the unfinished state before applying the reference solution.

- Pods in starfleet get team=unassigned only when they have no team label.
