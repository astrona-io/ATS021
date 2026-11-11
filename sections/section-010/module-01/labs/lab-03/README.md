---
estimated_duration: 15m
---

# Extend A Built-In Role Through Aggregation

The group `developers` already has the built-in `view` ClusterRole in `starfleet` through `developers-view`. It cannot read Leases.

Allow about 15 minutes of learner work, plus startup and reconciliation.

```sh
astrona run -c sections/section-010/module-01/labs/lab-03
astrona submit -c sections/section-010/module-01/labs/lab-03
astrona destroy ats-021-lab-010-01-03
```

The task is in [question.md](question.md), with a [reference walkthrough](solution.md). Authors run `astrona validate -c sections/section-010/module-01/labs/lab-03` and `astrona test -c sections/section-010/module-01/labs/lab-03`. The lifecycle checks the unfinished state before applying the reference solution.

- The developers group can list Leases in starfleet.
- The lease right comes from an aggregated ClusterRole.
