---
estimated_duration: 15m
---

# Require Container Limits With Kyverno

Kyverno is ready and no policies exist. Require resource limits for new Pods and Deployment templates in `starfleet`.

Allow about 15 minutes of learner work, plus startup and reconciliation.

```sh
astrona run -c sections/section-030/module-01/labs/lab-01
astrona submit -c sections/section-030/module-01/labs/lab-01
astrona destroy ats-021-lab-030-01
```

The task is in [question.md](question.md), with a [reference walkthrough](solution.md). Authors run `astrona validate -c sections/section-030/module-01/labs/lab-01` and `astrona test -c sections/section-030/module-01/labs/lab-01`. The lifecycle checks the unfinished state before applying the reference solution.

- Pods and Deployments in starfleet without CPU and memory limits are rejected.
- Pods with both limits are accepted, and outpost is not affected.
