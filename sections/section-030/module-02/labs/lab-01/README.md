---
estimated_duration: 30m
---

# Lab: Enforce Constraints With Gatekeeper And Rego

Graded lab for the Gatekeeper module. The cluster starts with Gatekeeper 3.23.1, the Starfleet workloads and a ConstraintTemplate whose Rego does not compile. `drifter` in `outpost` uses the `latest` image tag. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-030/module-02/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-030/module-02/labs/lab-01
astrona destroy ats-021-lab-030-02
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

The admission checks use `kubectl run --dry-run=server`, so the Gatekeeper webhook runs and nothing is stored.

| Script | What it proves |
| --- | --- |
| `validate-template-created.sh` | `k8sdisallowedtags` has `status.created: true`, its CustomResourceDefinition exists and the kind is unchanged |
| `validate-latest-denied-in-starfleet.sh` | Pods that use `curl:latest` or `podinfo:latest` are rejected in `starfleet` |
| `validate-pinned-tags-and-scope.sh` | `curl:8.22.0` is accepted in `starfleet`; `curl:latest` is accepted in `outpost` |
| `validate-audit-lists-drifter.sh` | A `dryrun` constraint lists the `drifter` pod in its `status.violations` (waits up to 3 minutes for the audit run) |

A `warn` or `dryrun` constraint in `starfleet` fails the second check, because the pod is then accepted. A `deny` constraint on `outpost` fails the third check.
