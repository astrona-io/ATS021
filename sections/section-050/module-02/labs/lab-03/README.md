---
estimated_duration: 15m
---

# Require Explicit Tags And Production Digests

Kyverno already enforces the GHCR registry boundary. Development still accepts `latest` and untagged images; production still accepts tags without a digest.

Allow about 15 minutes of learner work, plus startup and reconciliation.

```sh
astrona run -c sections/section-050/module-02/labs/lab-03
astrona submit -c sections/section-050/module-02/labs/lab-03
astrona destroy ats-021-lab-050-02-03
```

The task is in [question.md](question.md), with a [reference walkthrough](solution.md). Authors run `astrona validate -c sections/section-050/module-02/labs/lab-03` and `astrona test -c sections/section-050/module-02/labs/lab-03`. The lifecycle checks the unfinished state before applying the reference solution.

- The latest tag and a missing tag are rejected.
- starfleet-prod requires a digest and starfleet does not.
- Namespace labels are unchanged and namespaces without an environment label are not affected.
