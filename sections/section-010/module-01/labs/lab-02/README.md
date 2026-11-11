---
estimated_duration: 15m
---

# Replace An Excessive Service Account Grant

The `legacy-agent` service account in `starfleet` is bound to `cluster-admin`. It needs only to read Pods in its own namespace.

Allow about 15 minutes of learner work, plus startup and reconciliation.

```sh
astrona run -c sections/section-010/module-01/labs/lab-02
astrona submit -c sections/section-010/module-01/labs/lab-02
astrona destroy ats-021-lab-010-01-02
```

The task is in [question.md](question.md), with a [reference walkthrough](solution.md). Authors run `astrona validate -c sections/section-010/module-01/labs/lab-02` and `astrona test -c sections/section-010/module-01/labs/lab-02`. The lifecycle checks the unfinished state before applying the reference solution.

- legacy-agent is not bound to cluster-admin.
- legacy-agent reads pods in starfleet and nothing else.
