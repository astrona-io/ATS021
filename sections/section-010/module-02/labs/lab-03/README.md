---
estimated_duration: 15m
---

# Find A Baseline Violation Across Three Namespaces

Three application namespaces already exist: `navigation`, `telemetry` and `research`. Each contains one running Pod named `scout`. Exactly one Pod violates the baseline Pod Security Standard. Its namespace varies between lab starts.

Allow about 15 minutes of learner work, plus startup and reconciliation.

```sh
astrona run -c sections/section-010/module-02/labs/lab-03
astrona submit -c sections/section-010/module-02/labs/lab-03
astrona destroy ats-021-lab-010-02-03
```

The task is in [question.md](question.md), with a [reference walkthrough](solution.md). Authors run `astrona validate -c sections/section-010/module-02/labs/lab-03` and `astrona test -c sections/section-010/module-02/labs/lab-03`. The lifecycle checks the unfinished state before applying the reference solution.

- All three namespaces admit requests with baseline warnings.
- Only the namespace with the baseline violation is flagged.
- The original namespaces and running Pods are preserved.
