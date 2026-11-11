---
estimated_duration: 15m
---

# Grant Access To One Scale Subresource

The `scale-operator` service account has no resource permissions. It must change only the replica count of `starfleet/scout`, without permission to change the Deployment template.

Allow about 15 minutes of learner work, plus startup and reconciliation.

```sh
astrona run -c sections/section-010/module-01/labs/lab-04
astrona submit -c sections/section-010/module-01/labs/lab-04
astrona destroy ats-021-lab-010-01-04
```

The task is in [question.md](question.md), with a [reference walkthrough](solution.md). Authors run `astrona validate -c sections/section-010/module-01/labs/lab-04` and `astrona test -c sections/section-010/module-01/labs/lab-04`. The lifecycle checks the unfinished state before applying the reference solution.

- Grant Access To One Scale Subresource.
