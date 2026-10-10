# Record API Activity With Audit Logging

<!-- astrona:playground -->
> [!NOTE]
> This module has a playground — a throwaway environment to run the commands in.
> ```bash
> astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-040/module-01/playground
> ```

<!-- TODO(build): opening framing — what this module settles, and the contrast that sharpens its boundary. -->

## Learning objectives

- Write an audit policy that records Secret access at Metadata level, Deployment changes at RequestResponse and drops noisy read events
- Turn on audit logging by editing the kube-apiserver static pod manifest with the policy file, log path and volumes
- Confirm the API server restarted with the new flags and find the problem when it does not come back
- Find who deleted a Deployment, with which identity and when, in the audit log with jq
- Name the audit level and stage of a given event and say why a rule matched it

## Before you start

<!-- TODO(build): assumed knowledge, and what the playground already provides. -->

## Outline

<!-- TODO(build): each beat below becomes a section of this module (or a deep-dive part via /astrona-course-deep-dive). Delete this Outline section once written. -->

- What an audit event holds; levels and stages
- Audit policy rules: first match wins, omitStages, levels per resource and user
- Turning it on - the kube-apiserver static pod, flags, volumes, waiting for the restart
- Searching the log with jq for one action

## Diagrams planned

<!-- TODO(build): mermaid `sequence` — One request through the API server and the audit events written at each stage -->
<!-- TODO(build): mermaid `flowchart` — Audit policy rule matching - first matching rule decides the level, otherwise None -->

<!-- playground provides: kind cluster with no audit logging configured. Starfleet workloads in `starfleet`. A background `CronJob` named `deck-cleaner` in `outpost` running as service account `deck-cleaner` with rights to read Secrets and delete Deployments in `starfleet`, which every few minutes reads a Secret and deletes and recreates the `probe` Deployment (the activity to find in the log). The reader opens a shell on the control plane node container with docker exec or podman exec; `jq` is available on the node or the reader copies the log out. -->

<!-- module section-040/module-01 (Module 1) — stub written by /astrona-course-domain-scaffold, prose written by /astrona-course-domain-build. -->
