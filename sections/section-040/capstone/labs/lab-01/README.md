---
estimated_duration: 45m
---

# Capstone: Audit Trails And Compliance Evidence

Graded capstone for the audit and compliance section. The cluster starts with Kyverno 1.19.1, Gatekeeper 3.23.1, two Kyverno policies in `Audit` mode, one Gatekeeper Constraint in `dryrun` mode, the Starfleet workloads with known violations, the `deck-cleaner` CronJob that deletes and recreates `beacon` every two minutes, and no audit logging. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-040/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-040/capstone/labs/lab-01
astrona destroy ats-021-capstone-040
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`. The test needs `podman` or `docker`, because the reference solution edits the static pod manifest on the control plane node.

## Checks

The graders read the audit log with a short-lived pod `audit-grader-reader-<pid>` in `kube-system` on the control plane node. The pod mounts `/var/log/kubernetes/audit` read-only. Each script creates a real request (a Secret read, a Deployment create and delete) and looks for that event in the log. The answer graders read the live PolicyReports, the Constraint status and the audit log and compare them to the ConfigMap `auditor-answers` in `starfleet`.

| Script | What it proves |
| --- | --- |
| `validate-audit-logging-enabled.sh` | The kube-apiserver pod has `--audit-policy-file` and `--audit-log-path=/var/log/kubernetes/audit/audit.log`, `/readyz` answers and the log has events |
| `validate-secret-metadata-only.sh` | A Secret read is in the log at level `Metadata`, with no request or response body |
| `validate-deployment-bodies-recorded.sh` | A Deployment create and delete are in the log at level `RequestResponse`, and the create holds both bodies |
| `validate-noise-dropped.sh` | New events hold no health check request and no `RequestReceived` stage, but the log is not empty |
| `validate-deletion-answer.sh` | `deletion-audit-id` is a successful `delete` of `beacon` in the log, made by the service account of the CronJob, and `deleted-by` matches the event |
| `validate-kyverno-answer.sh` | `kyverno-failing` equals the Deployments with a failed result in the live `PolicyReport` objects |
| `validate-gatekeeper-answer.sh` | `owner-label` equals the Deployments in `status.violations` of the Constraint |
| `validate-evidence-intact.sh` | Both policies are `Audit`, the Constraint is `dryrun`, the violating workloads still violate and audit logging is on |

A policy that records nothing, or Deployments at `Metadata`, fails the audit checks. An answer written from memory or from another cluster fails, because the graders compare it to the live evidence. Fixing the violating workloads, or switching a policy to `Enforce`, fails the last check.
