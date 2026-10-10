# Admit Only Trusted Images

<!-- astrona:playground -->
> [!NOTE]
> This module has a playground — a throwaway environment to run the commands in.
> ```bash
> astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-050/module-02/playground
> ```

<!-- TODO(build): opening framing — what this module settles, and the contrast that sharpens its boundary. -->

## Learning objectives

- Write a Kyverno ClusterPolicy that admits images only from approved registries
- Reject images with the latest tag or without a tag, and require images pinned by digest in production namespaces
- Write the same allowed-registry rule as a Gatekeeper ConstraintTemplate and Constraint
- Read each rejection message and prove the policy with one rejected and one accepted Deployment
- Explain why a tag can point at different content over time and a digest cannot

## Before you start

<!-- TODO(build): assumed knowledge, and what the playground already provides. -->

## Outline

<!-- TODO(build): each beat below becomes a section of this module (or a deep-dive part via /astrona-course-deep-dive). Delete this Outline section once written. -->

- Tags, digests and why an image reference is a supply chain decision
- Allowed registries with a Kyverno validate rule and with Gatekeeper
- Disallowing latest and requiring digests; applying rules per namespace
- Testing image policies with server-side dry runs

## Diagrams planned

<!-- TODO(build): mermaid `sequence` — Deployment create through the API server to the policy webhook - image reference checked against registry, tag and digest rules, admit or reject -->

<!-- playground provides: kind cluster with Kyverno 1.19.1 and Gatekeeper 3.23.1 installed, no image policy yet. Namespaces `starfleet` and `starfleet-prod`. podinfo 6.15.0 preloaded under its tag and known digest, plus a `docker.io/library/nginx:latest` reference to try (preloaded). No registry of its own and no signing tools. -->

<!-- module section-050/module-02 (Module 2) — stub written by /astrona-course-domain-scaffold, prose written by /astrona-course-domain-build. -->
