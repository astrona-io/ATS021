---
estimated_duration: 45m
---

# Lab: Governance With Policy Engines And Admission Control Capstone

Graded capstone for the section. The cluster starts with Kyverno 1.19.1, Gatekeeper 3.23.1 (with the working `K8sDisallowedTags` template), their webhooks ready, and the Starfleet workloads. No policy exists. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-030/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-030/capstone/labs/lab-01
astrona destroy ats-021-capstone-030
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

The graders use `kubectl create --dry-run=server` and `kubectl scale --dry-run=server`, so every webhook and admission policy runs and nothing is stored.

| Script | What it proves |
| --- | --- |
| `validate-limits-enforced.sh` | A pod and a Deployment without limits are rejected in `starfleet`; a pod with limits is accepted; `outpost` is not affected |
| `validate-probe-exempt-only.sh` | A pod labelled `app=probe` without limits is accepted; pods labelled `app=beacon` or `app=probe-extra` without limits are rejected |
| `validate-latest-tag-denied.sh` | A pod with limits and the `latest` tag is rejected in `starfleet`; a pinned tag is accepted |
| `validate-beacon-fixed-audit-clean.sh` | `beacon` has a pinned tag, the template still exists, and every denying constraint reports `totalViolations` 0 |
| `validate-replica-limit-in-production.sh` | A Deployment with 6 replicas and a scale of `scout` to 9 are rejected in `starfleet`; 5 replicas are accepted; `outpost` is not blocked |
| `validate-scout-within-limit.sh` | `scout` runs between 1 and 5 replicas |

The blueprint asks for a Kyverno `PolicyException` for the legacy workload. Exceptions are off by default in Kyverno 1.19.1 and enabling them did not work in the playground, so the lab asks for a narrow exemption inside the policy instead. A policy in `Audit` mode, a policy that excludes the whole namespace, and a constraint in `dryrun` mode each fail a check.
