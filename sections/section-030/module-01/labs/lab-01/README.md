---
estimated_duration: 30m
---

# Lab: Validate, Mutate And Generate With Kyverno

Graded lab for the Kyverno module. The cluster starts with Kyverno 1.19.1, its webhooks ready, the Starfleet workloads and no policy. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-030/module-01/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-030/module-01/labs/lab-01
astrona destroy ats-021-lab-030-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

The graders use `kubectl create --dry-run=server`, so every Kyverno webhook runs and nothing is stored.

| Script | What it proves |
| --- | --- |
| `validate-limits-rule-rejects-pods.sh` | A pod with no limits, a memory-only limit or a CPU-only limit, and a Deployment with no limits, are rejected in `starfleet` |
| `validate-limits-rule-allows-good-pods.sh` | A pod with both limits is accepted in `starfleet`; a pod with no limits is accepted in `outpost` |
| `validate-team-label-default.sh` | A pod without `team` gets `unassigned`; `team: blue` stays; `outpost` is not changed |
| `validate-default-deny-generated.sh` | A new namespace gets the NetworkPolicy `default-deny` with an empty pod selector and both policy types |

A policy in `Audit` mode fails the first check, because the pod is then accepted. A policy that matches every namespace fails the second check.
