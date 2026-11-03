---
estimated_duration: 30m
---

# Lab: Record API Activity With Audit Logging

Graded lab for the audit logging module. The cluster starts with the Starfleet workloads, the `deck-cleaner` CronJob in `outpost` and no audit logging on the API server. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-040/module-01/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-040/module-01/labs/lab-01
astrona destroy ats-021-lab-040-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`. The test needs `podman` or `docker`, because the reference solution edits the static pod manifest on the control plane node (`astro-ats-021-lab-040-01-control-plane`).

## Checks

The graders read the audit log with `kubectl` only. Each script starts a short-lived pod `audit-grader-reader` in `kube-system` on the control plane node. The pod mounts `/var/log/kubernetes/audit` read-only, and the script reads the log with `kubectl exec`. The pod is deleted when the script ends. Each script creates a real request first (a Secret read, a Deployment create and delete) and looks for that event in the log, so only events written after the grader started count.

| Script | What it proves |
| --- | --- |
| `validate-audit-logging-enabled.sh` | The kube-apiserver pod has `--audit-policy-file` and `--audit-log-path=/var/log/kubernetes/audit/audit.log`, `/readyz` answers and the log has events |
| `validate-secret-metadata-only.sh` | A Secret read is in the log at level `Metadata`, with no `requestObject` and no `responseObject` |
| `validate-deployment-bodies-recorded.sh` | A Deployment create and delete in `starfleet` are in the log at level `RequestResponse`, and the create holds both bodies |
| `validate-noise-dropped.sh` | New events hold no `/healthz`, `/livez` or `/readyz` request and no `RequestReceived` stage, but the log is not empty |
| `validate-probe-deletion-evidence.sh` | The ConfigMap `probe-deletion` in `starfleet` holds the `auditID` of a successful `delete` of `probe` in the log, and the `user` matches the event and the service account of the CronJob |

A policy that records nothing fails the second check. A policy that records Deployments at `Metadata` fails the third. A policy that records Secrets at `RequestResponse` fails the second. A made-up `auditID` fails the last check. The last check passes only after the CronJob has run once with logging on, which takes up to two minutes.
