---
estimated_duration: 15m
---

# Enforce A Registry Boundary With Kyverno

Kyverno runs with an Audit-mode `allowed-registries` policy. `starfleet` has `environment: development`; `starfleet-prod` has `environment: production`. Other namespaces have no environment label.

Allow about 15 minutes of learner work, plus startup and reconciliation.

```sh
astrona run -c sections/section-050/module-02/labs/lab-01
astrona submit -c sections/section-050/module-02/labs/lab-01
astrona destroy ats-021-lab-050-02
```

The task is in [question.md](question.md), with a [reference walkthrough](solution.md). Authors run `astrona validate -c sections/section-050/module-02/labs/lab-01` and `astrona test -c sections/section-050/module-02/labs/lab-01`. The lifecycle checks the unfinished state before applying the reference solution.

- Images from a registry other than ghcr.io are rejected in namespaces with an environment label.
- Namespace labels are unchanged and namespaces without an environment label are not affected.
