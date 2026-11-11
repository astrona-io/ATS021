---
estimated_duration: 15m
---

# Gate A Tekton Release On A Compliance Result

Tekton, `deploy-release`, the policy and release ConfigMaps are ready. `pipeline-runner` already has limited deployment access. The Pipeline has no check Task and does not gate deployment.

Allow about 15 minutes of learner work, plus startup and reconciliation.

```sh
astrona run -c sections/section-050/module-01/labs/lab-01
astrona submit -c sections/section-050/module-01/labs/lab-01
astrona destroy ats-021-lab-050-01
```

The task is in [question.md](question.md), with a [reference walkthrough](solution.md). Authors run `astrona validate -c sections/section-050/module-01/labs/lab-01` and `astrona test -c sections/section-050/module-01/labs/lab-01`. The lifecycle checks the unfinished state before applying the reference solution.

- A compliant release is checked, the check writes pass and the deploy Task creates the Deployment in starfleet.
- A release without limits and a release with the latest tag are not deployed, because the deploy Task is skipped.
