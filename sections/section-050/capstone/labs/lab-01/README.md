---
estimated_duration: 60m
---

# Capstone: Gate A Release Pipeline And Restrict Production Images

Graded capstone for the section on security checks in the delivery pipeline. The cluster starts with Tekton Pipelines 1.17.0 and Kyverno 1.19.1, the namespaces `pipelines`, `starfleet` (`environment: development`), `starfleet-prod` (`environment: production`) and `outpost`, and the service account `pipeline-runner` with the built-in `edit` role in `starfleet` and `outpost`. The Tasks `deploy-release` and `report-outcome` exist. The Pipeline `release-gate` only deploys, and the policy `trusted-images` is in `Audit` mode. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-050/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-050/capstone/labs/lab-01
astrona destroy ats-021-capstone-050
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

The four pipeline checks create their own policy file and releases in the `pipelines` namespace (names start with `grader-`), start the Pipeline `release-gate` with the service account `pipeline-runner` and read the TaskRuns. The two image checks use `kubectl create deployment --dry-run=server`, so every Kyverno webhook runs and nothing is stored.

| Script | What it proves |
| --- | --- |
| `validate-compliant-release-deployed.sh` | A compliant release gets `pass` from `check` and the Deployment exists in `starfleet` |
| `validate-noncompliant-release-blocked.sh` | A release without limits and a release with the `latest` tag get `fail`, `deploy` is skipped and nothing is deployed |
| `validate-finally-runs-on-every-path.sh` | The `finally` Task runs after a deployed, a blocked and a failed release |
| `validate-service-account-least-privilege.sh` | `pipeline-runner` can `get`, `create` and `patch` Deployments in `starfleet` and nothing else; `outpost` is not deployed |
| `validate-production-images-restricted.sh` | `starfleet-prod` rejects other registries and images with no digest, and accepts a `ghcr.io` image with a digest |
| `validate-other-namespaces-unaffected.sh` | `starfleet` accepts a tag, `default` accepts `nginx:latest`, the labels are unchanged and Kyverno runs |
