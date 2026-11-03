---
estimated_duration: 30m
---

# Lab: Write ValidatingAdmissionPolicies With CEL

Graded lab for the ValidatingAdmissionPolicy module. The cluster has no policy engine: the API server does the work. `starfleet` is labelled `environment: production` and `scout` runs 8 replicas. `outpost` is labelled `environment: sandbox`. The ConfigMap `replica-limits` holds `maxReplicas: "5"`. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-030/module-03/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-030/module-03/labs/lab-01
astrona destroy ats-021-lab-030-03
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

The admission checks use `--dry-run=server`, so every admission step runs and nothing is stored.

| Script | What it proves |
| --- | --- |
| `validate-replica-limit-denied-in-production.sh` | In `starfleet`, a new Deployment with 6 replicas, `kubectl scale` to 9 and a patch to 9 are rejected; 5 replicas are accepted |
| `validate-over-limit-deployment-can-shrink.sh` | `scout` (8 replicas) can be scaled to 6 and 3 and can get a label; a binding with `Deny` exists |
| `validate-sandbox-warns.sh` | In `outpost`, 6 replicas are accepted with a `Warning:`; 2 replicas give no warning; a binding with `Warn` exists |
| `validate-limit-comes-from-params.sh` | The policy has `paramKind` `v1/ConfigMap`, reads `params.data`, every binding names `replica-limits`, and the expression has no fixed `5` |

A `Warn` binding in `starfleet` fails the first check. A policy that only matches `deployments` fails the scale checks.
