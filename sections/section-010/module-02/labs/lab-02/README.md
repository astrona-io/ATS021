---
estimated_duration: 15m
---

# Stage Restricted Pod Security With Warnings

The application Pods pass the baseline Pod Security Standard but do not meet restricted. The namespace has no Pod Security labels. Prepare the team for restricted without blocking baseline-compliant replacement Pods.

Allow about 15 minutes of learner work, plus startup and reconciliation.

```sh
astrona run -c sections/section-010/module-02/labs/lab-02
astrona submit -c sections/section-010/module-02/labs/lab-02
astrona destroy ats-021-lab-010-02-02
```

The task is in [question.md](question.md), with a [reference walkthrough](solution.md). Authors run `astrona validate -c sections/section-010/module-02/labs/lab-02` and `astrona test -c sections/section-010/module-02/labs/lab-02`. The lifecycle checks the unfinished state before applying the reference solution.

- Stage Restricted Pod Security With Warnings.
