---
estimated_duration: 15m
---

# Require Istio Mutual TLS

`starfleet` has Istio sidecars but accepts plaintext traffic. `drifter` in `outpost` has no sidecar. No authentication or authorization policy exists.

Allow about 15 minutes of learner work, plus startup and reconciliation.

```sh
astrona run -c sections/section-020/module-01/labs/lab-01
astrona submit -c sections/section-020/module-01/labs/lab-01
astrona destroy ats-021-lab-020-01
```

The task is in [question.md](question.md), with a [reference walkthrough](solution.md). Authors run `astrona validate -c sections/section-020/module-01/labs/lab-01` and `astrona test -c sections/section-020/module-01/labs/lab-01`. The lifecycle checks the unfinished state before applying the reference solution.

- starfleet refuses plain-text requests and still serves mesh clients.
