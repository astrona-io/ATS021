---
estimated_duration: 15m
---

# Limit A Tekton Deployment Identity

The Pipeline already checks compliance, gates deployment and reports the outcome. Its `pipeline-runner` identity has a ClusterRoleBinding to `edit`, so it can deploy into unrelated namespaces.

Allow about 15 minutes of learner work, plus startup and reconciliation.

```sh
astrona run -c sections/section-050/module-01/labs/lab-03
astrona submit -c sections/section-050/module-01/labs/lab-03
astrona destroy ats-021-lab-050-01-03
```

The task is in [question.md](question.md), with a [reference walkthrough](solution.md). Authors run `astrona validate -c sections/section-050/module-01/labs/lab-03` and `astrona test -c sections/section-050/module-01/labs/lab-03`. The lifecycle checks the unfinished state before applying the reference solution.

- A compliant release is checked, the check writes pass and the deploy Task creates the Deployment in starfleet.
- A release without limits and a release with the latest tag are not deployed, because the deploy Task is skipped.
- pipeline-runner may get, create and patch Deployments in starfleet and nothing else, and a release for outpost is not deployed.
