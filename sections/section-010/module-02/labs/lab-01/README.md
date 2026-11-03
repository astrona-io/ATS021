---
estimated_duration: 20m
---

# Lab: Restrict Pods With Pod Security Admission

Graded lab for the Pod Security Admission module. The `starfleet` namespace starts with no Pod Security labels, three workloads without a `securityContext`, and a privileged Deployment. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-010/module-02/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-010/module-02/labs/lab-01
astrona destroy ats-021-lab-010-02
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-restricted-enforced.sh` | The label `pod-security.kubernetes.io/enforce` on `starfleet` is exactly `restricted` (not `baseline`, not `privileged`) |
| `validate-privileged-pod-rejected.sh` | A server-side dry run of a privileged pod fails with `violates PodSecurity`; a pod with the four settings is accepted |
| `validate-privileged-debug-removed.sh` | The `privileged-debug` Deployment and its pods are gone |
| `validate-workloads-comply.sh` | `scout`, `probe` and `shuttle` exist, every replica is available, and every running pod has the four settings (a label set while old pods keep running fails here) |
| `validate-scout-serves.sh` | `shuttle` gets HTTP 200 from the `scout` Service |

`scout-still-serves` passes before any change, because the workloads run. It fails if a change breaks `scout`.
