---
estimated_duration: 15m
---

# Grant Deployment Access In One Namespace

The `ci-deployer` service account in `starfleet` has no resource permissions. Give this deployment pipeline access to one namespace.

Allow about 15 minutes of learner work, plus startup and reconciliation.

```sh
astrona run -c sections/section-010/module-01/labs/lab-01
astrona submit -c sections/section-010/module-01/labs/lab-01
astrona destroy ats-021-lab-010-01
```

The task is in [question.md](question.md), with a [reference walkthrough](solution.md). Authors run `astrona validate -c sections/section-010/module-01/labs/lab-01` and `astrona test -c sections/section-010/module-01/labs/lab-01`. The lifecycle checks the unfinished state before applying the reference solution.

- ci-deployer can read, create and change Deployments in starfleet.
- ci-deployer has no other rights.
