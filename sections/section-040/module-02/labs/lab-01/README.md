---
estimated_duration: 30m
---

# Lab: Produce Compliance Reports From Policy Engines

Graded lab for the compliance reports module. The cluster starts with Kyverno 1.19.1, Gatekeeper 3.23.1, two Kyverno policies in `Audit` mode, one Gatekeeper Constraint in `dryrun` mode, the Starfleet workloads with known violations, API server audit logging and one scale of `relay` by a service account. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-040/module-02/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-040/module-02/labs/lab-01
astrona destroy ats-021-lab-040-02
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`. The test needs `podman` or `docker`, because the reference solution reads the audit log from the control plane node.

## Checks

The learner writes the answers to the ConfigMap `auditor-answers` in `starfleet`. Every grader reads the live evidence itself and compares it to the answer, so an answer copied from another cluster or another lab fails when the data differs. The audit grader reads the log with a short-lived pod `audit-grader-reader` in `kube-system` that mounts `/var/log/kubernetes/audit` read-only.

| Script | What it proves |
| --- | --- |
| `validate-kyverno-answers.sh` | The keys `require-limits` and `disallow-latest-tag` list the Deployments (`namespace/name`) that fail each policy in the live `PolicyReport` objects |
| `validate-gatekeeper-answer.sh` | The key `owner-label` lists the Deployments in `status.violations` of the Constraint `deployments-need-owner` |
| `validate-audit-answers.sh` | The key `relay-scaled-by` equals the `user.username` of the successful scale of `relay` in the audit log, and `source-for-who-scaled` is `audit-log` |
| `validate-evidence-intact.sh` | Both policies are still `Audit`, the Constraint is still `dryrun`, `probe`, `drifter` and `relay` still violate, and audit logging is still on |

An empty answer fails, because the live evidence is not empty. Fixing the violating workloads, switching a policy to `Enforce` or turning off audit logging fails the last check.
