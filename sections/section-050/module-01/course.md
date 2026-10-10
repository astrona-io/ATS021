# Gate A Tekton Pipeline On A Compliance Check

<!-- astrona:playground -->
> [!NOTE]
> This module has a playground — a throwaway environment to run the commands in.
> ```bash
> astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-050/module-01/playground
> ```

<!-- TODO(build): opening framing — what this module settles, and the contrast that sharpens its boundary. -->

## Learning objectives

- Write a Tekton Task whose step checks the release manifests against the platform's policies and writes the outcome to a Task result
- Stop the deploy Task with a when expression that reads the check Task's result
- Add a finally Task that always reports the outcome, even when the pipeline fails
- Run a PipelineRun and read why a Task failed or was skipped with tkn and kubectl
- Give the pipeline's service account only the rights its deploy step needs

## Before you start

<!-- TODO(build): assumed knowledge, and what the playground already provides. -->

## Outline

<!-- TODO(build): each beat below becomes a section of this module (or a deep-dive part via /astrona-course-deep-dive). Delete this Outline section once written. -->

- Tekton Task, Pipeline, PipelineRun; where steps run and what a step image is
- A compliance check step - the check is one step image, the Tekton parts are the subject
- Task results, when expressions and runAfter; skipped versus failed Tasks
- finally Tasks; reading a run; the pipeline service account

## Diagrams planned

<!-- TODO(build): mermaid `flowchart` — PipelineRun with check Task, a when expression on its result, deploy Task, and a finally Task that runs on every path -->

<!-- playground provides: kind cluster with Tekton Pipelines 1.17.0 and the tkn 0.46.1 CLI. Namespace `pipelines` with service account `pipeline-runner` that can create Deployments in `starfleet` only. A prepared deploy Task that applies the `scout` Deployment from manifests in a ConfigMap. Two manifest sets to try: a compliant `scout` release and a release without resource limits that uses the `latest` tag. The check step runs the Kyverno CLI image (ghcr.io/kyverno/kyverno-cli:v1.19.1) against a platform policy file; the lesson treats it as one step image, not a tool to learn. No check Task yet. -->

<!-- module section-050/module-01 (Module 1) — stub written by /astrona-course-domain-scaffold, prose written by /astrona-course-domain-build. -->
