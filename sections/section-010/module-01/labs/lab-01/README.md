---
estimated_duration: 20m
---

# Lab: Grant Least-Privilege Access With RBAC

Graded lab for the RBAC module. The cluster starts with a service account that has no rights, a service account bound to `cluster-admin`, and a built-in role that lacks Leases. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-010/module-01/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-010/module-01/labs/lab-01
astrona destroy ats-021-lab-010-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-ci-deployer-can-manage-deployments.sh` | `ci-deployer` can read, create, update and patch Deployments in `starfleet` (can-i and a real annotate) |
| `validate-ci-deployer-least-privilege.sh` | It cannot delete Deployments, read Secrets, create pods, use `outpost`, or use a wildcard |
| `validate-legacy-agent-cluster-admin-removed.sh` | No binding of `legacy-agent` to `cluster-admin` remains; the service account still exists |
| `validate-legacy-agent-reads-pods-only.sh` | It reads pods in `starfleet` only (a ClusterRoleBinding to `view` fails the `outpost` check) |
| `validate-developers-can-list-leases.sh` | `developers` can list Leases in `starfleet`, not in `outpost`, and cannot read Secrets |
| `validate-view-extended-by-aggregation.sh` | The lease rule comes from a ClusterRole labelled `aggregate-to-view`; `view` keeps its `aggregationRule` |

`ci-deployer-least-privilege` passes before any change, because the account has no rights yet. It fails if a too-broad grant is added.
