---
estimated_duration: 30m
---

# Capstone: Access Control For Platform Resources

Graded integration lab for the whole section. A new team namespace `orbit` starts with a service account bound to `cluster-admin`, no Pod Security labels and a workload that breaks the `restricted` level. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-010/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-010/capstone/labs/lab-01
astrona destroy ats-021-capstone-010
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-ci-deployer-manages-orbit.sh` | `ci-deployer` can read, create, change and delete Deployments and Services in `orbit` (can-i and real annotate requests) |
| `validate-ci-deployer-least-privilege.sh` | It cannot read Secrets, create pods, use another namespace, list cluster-wide, or use a wildcard |
| `validate-cluster-admin-removed.sh` | No binding of `ci-deployer` to `cluster-admin` remains; the service account still exists |
| `validate-orbit-enforces-restricted.sh` | The enforce label is exactly `restricted`; a privileged pod is rejected and a restricted pod accepted (server-side dry runs) |
| `validate-beacon-admitted-and-running.sh` | `beacon` is available, its running pods have the four settings, and its Service has an endpoint |

`ci-deployer-manages-orbit` passes before any change, because `cluster-admin` allows everything. `ci-deployer-least-privilege` and `cluster-admin-removed` catch a learner who only adds the Role.
