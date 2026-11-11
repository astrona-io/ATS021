---
estimated_duration: 15m
---

# Repair CEL Type And Missing-Key Errors

The enforcing `workload-check` policy in `starfleet` rejects compliant Deployments. One expression reads `replica` instead of `replicas`; another reads `labels.team` without checking whether the key exists. The same binding must continue enforcing both rules.

Allow about 15 minutes of learner work, plus startup and reconciliation.

```sh
astrona run -c sections/section-030/module-03/labs/lab-02
astrona submit -c sections/section-030/module-03/labs/lab-02
astrona destroy ats-021-lab-030-03-02
```

The task is in [question.md](question.md), with a [reference walkthrough](solution.md). Authors run `astrona validate -c sections/section-030/module-03/labs/lab-02` and `astrona test -c sections/section-030/module-03/labs/lab-02`. The lifecycle checks the unfinished state before applying the reference solution.

- Repair CEL Type And Missing-Key Errors.
