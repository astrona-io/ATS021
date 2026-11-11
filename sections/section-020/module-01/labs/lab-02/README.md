---
estimated_duration: 15m
---

# Authorize Istio Callers And Methods

STRICT mutual TLS already protects `starfleet`. Meshed clients can still call any `scout` endpoint. `caller` uses the `probe` service account; `shuttle` has its own identity.

Allow about 15 minutes of learner work, plus startup and reconciliation.

```sh
astrona run -c sections/section-020/module-01/labs/lab-02
astrona submit -c sections/section-020/module-01/labs/lab-02
astrona destroy ats-021-lab-020-01-02
```

The task is in [question.md](question.md), with a [reference walkthrough](solution.md). Authors run `astrona validate -c sections/section-020/module-01/labs/lab-02` and `astrona test -c sections/section-020/module-01/labs/lab-02`. The lifecycle checks the unfinished state before applying the reference solution.

- starfleet refuses plain-text requests and still serves mesh clients.
- shuttle can send GET requests to scout.
- scout refuses other identities and other methods with 403.
- The /env path of scout is denied for every caller.
