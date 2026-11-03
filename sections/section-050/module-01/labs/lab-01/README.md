---
estimated_duration: 40m
---

# Lab: Gate A Tekton Pipeline On A Compliance Check

Graded lab for the Tekton module. The cluster starts with Tekton Pipelines 1.17.0, the service account `pipeline-runner` with a grant that is too broad, the Tasks `deploy-release` and `report-outcome`, and an unfinished Pipeline `release-gate`. There is no check Task. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-050/module-01/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-050/module-01/labs/lab-01
astrona destroy ats-021-lab-050-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

Every check creates its own policy file and its own releases in the `pipelines` namespace (names start with `grader-`), starts the Pipeline `release-gate` with the service account `pipeline-runner` and reads the TaskRuns. The scripts delete their fixtures and runs when they end.

| Script | What it proves |
| --- | --- |
| `validate-compliant-release-deployed.sh` | A compliant release runs `check` (result `outcome` is `pass`) and `deploy`, and the Deployment exists in `starfleet` |
| `validate-noncompliant-release-blocked.sh` | A release without limits and a release with the `latest` tag get `fail`, the `deploy` Pipeline Task is in the skipped list of the run, and nothing is deployed |
| `validate-finally-runs-on-every-path.sh` | The `finally` Task has a successful TaskRun after a deployed release, a blocked release and a release whose deploy fails |
| `validate-service-account-least-privilege.sh` | `pipeline-runner` can `get`, `create` and `patch` Deployments in `starfleet` and cannot do other things; a release for `outpost` is not deployed |

Always passing `pass`, or always passing `fail`, fails the first two checks. Binding `cluster-admin` fails the last check. Removing all rights from `pipeline-runner` fails the first check. The reference solution applies the files in `solution/`.
