---
estimated_duration: 25m
---

# Lab: Require Mutual TLS And Authorize Callers With Linkerd

Graded lab for the Linkerd module. The cluster starts with Linkerd's default inbound policy `all-unauthenticated` and no policy resource: any caller, with or without a proxy, can send any request to `scout` and `probe`. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-020/module-02/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-020/module-02/labs/lab-01
astrona destroy ats-021-lab-020-02
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-scout-allows-only-shuttle.sh` | `shuttle` gets `200` from `scout`; `drifter` (no proxy) and `caller` (meshed, `probe` identity) get `403` |
| `validate-probe-refuses-unmeshed.sh` | `drifter` gets `403` from `probe` |
| `validate-probe-serves-meshed-callers.sh` | `shuttle` and `caller` get `200` from `probe` |

`caller` is a meshed client in `starfleet` that runs as the `probe` service account. `probe-serves-meshed-callers` passes before any change and guards against a policy that locks `probe` for everyone. The graders retry for about 30 seconds. They do not restart workloads: the learner must restart them after changing the default inbound policy, as the course teaches.
