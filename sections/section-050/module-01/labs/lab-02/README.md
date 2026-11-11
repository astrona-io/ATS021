---
estimated_duration: 15m
---

# Report Every Tekton Pipeline Outcome

The compliance Task, conditional deploy and limited service account already work. The Pipeline has no finally Task. Prepared releases are `release-compliant`, `release-noncompliant` and `release-outpost` in `pipelines`.

Allow about 15 minutes of learner work, plus startup and reconciliation.

```sh
astrona run -c sections/section-050/module-01/labs/lab-02
astrona submit -c sections/section-050/module-01/labs/lab-02
astrona destroy ats-021-lab-050-01-02
```

The task is in [question.md](question.md), with a [reference walkthrough](solution.md). Authors run `astrona validate -c sections/section-050/module-01/labs/lab-02` and `astrona test -c sections/section-050/module-01/labs/lab-02`. The lifecycle checks the unfinished state before applying the reference solution.

- A compliant release is checked, the check writes pass and the deploy Task creates the Deployment in starfleet.
- A release without limits and a release with the latest tag are not deployed, because the deploy Task is skipped.
- A finally Task runs after a deployed, a blocked and a failed release.
