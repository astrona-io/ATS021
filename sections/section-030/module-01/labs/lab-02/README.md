---
estimated_duration: 20m
---

# Lab: Default Pod Labels With A NamespacedMutatingPolicy

Write and test a Kyverno 1.19.1 namespaced mutation policy. The lab provides
Kubernetes 1.35.8, the Kyverno CLI 1.19.1 on the terminal, service accounts,
a preloaded podinfo image and offline test fixtures. The task is in
`question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-030/module-01/labs/lab-02
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-030/module-01/labs/lab-02
astrona destroy ats-021-lab-030-01-02
```

## Checks

| Script | What it proves |
| --- | --- |
| `validate-policy-offline.sh` | The saved v1 namespaced policy matches live state, selects Pod CREATE and UPDATE, and passes the pinned CLI against trusted fixtures |
| `validate-admission-default.sh` | Real admission defaults missing labels on CREATE and UPDATE, keeps unrelated and human labels, and leaves outpost untouched |
| `validate-student-pods.sh` | Two saved Pods demonstrate defaulting, and a human value survives another UPDATE |

Every check requires a policy absent from the starting state. Temporary
grader Pods are deleted on exit. The reference solution is `solution/apply.sh`.
Built without booting on 2026-11-04; live behavior has not been executed here.
