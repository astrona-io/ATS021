# Require Mutual TLS And Authorize Callers With Linkerd

<!-- astrona:playground -->
> [!NOTE]
> This module has a playground — a throwaway environment to run the commands in.
> ```bash
> astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-020/module-02/playground
> ```

<!-- TODO(build): opening framing — what this module settles, and the contrast that sharpens its boundary. -->

## Learning objectives

- Inject the Linkerd proxy into a namespace and confirm with linkerd viz edges or linkerd check that connections use mTLS
- Name the Linkerd identity of a workload from its service account
- Write a Server and an AuthorizationPolicy with a MeshTLSAuthentication that let only shuttle call scout
- Set a default inbound policy (all-unauthenticated, all-authenticated, deny) and predict who is refused
- Map each Linkerd resource to the Istio resource that does the same job

## Before you start

<!-- TODO(build): assumed knowledge, and what the playground already provides. -->

## Outline

<!-- TODO(build): each beat below becomes a section of this module (or a deep-dive part via /astrona-course-deep-dive). Delete this Outline section once written. -->

- Linkerd's automatic mTLS and identity, compared with Istio's
- Default inbound policy annotations and what each value allows
- Server, AuthorizationPolicy, MeshTLSAuthentication: selecting a port and naming allowed identities
- Proving the result from shuttle and drifter

## Diagrams planned

<!-- TODO(build): mermaid `er` — Server - AuthorizationPolicy - MeshTLSAuthentication - ServiceAccount, and what each one selects -->

<!-- playground provides: kind cluster with Linkerd edge-26.10.1 (CRDs, control plane and the viz extension) installed by the linkerd CLI, no Istio. Namespace `starfleet` annotated for proxy injection with `scout`, `probe` and `shuttle`; namespace `outpost` without injection running `drifter`. Default inbound policy left at all-unauthenticated, no Server or AuthorizationPolicy yet, so drifter can reach scout at the start. -->

<!-- module section-020/module-02 (Module 2) — stub written by /astrona-course-domain-scaffold, prose written by /astrona-course-domain-build. -->
