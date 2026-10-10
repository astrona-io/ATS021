# Write ValidatingAdmissionPolicies With CEL

<!-- astrona:playground -->
> [!NOTE]
> This module has a playground — a throwaway environment to run the commands in.
> ```bash
> astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-030/module-03/playground
> ```

<!-- TODO(build): opening framing — what this module settles, and the contrast that sharpens its boundary. -->

## Learning objectives

- Write a ValidatingAdmissionPolicy with a CEL expression that limits Deployment replicas
- Bind it to selected namespaces with a ValidatingAdmissionPolicyBinding and choose Deny, Warn or Audit
- Pass a limit through a params resource instead of hard-coding it
- Choose between ValidatingAdmissionPolicy, Kyverno and Gatekeeper for a given rule and say why

## Before you start

<!-- TODO(build): assumed knowledge, and what the playground already provides. -->

## Outline

<!-- TODO(build): each beat below becomes a section of this module (or a deep-dive part via /astrona-course-deep-dive). Delete this Outline section once written. -->

- In-process admission with CEL and no webhook - what changes compared with Kyverno and Gatekeeper
- CEL expressions: object, oldObject, request, messageExpression
- The binding: matchResources, paramRef, validationActions
- Choosing the right tool for a rule

## Diagrams planned

<!-- TODO(build): mermaid `flowchart` — ValidatingAdmissionPolicy, its binding and an optional params ConfigMap, and where each validationAction ends -->

<!-- playground provides: kind cluster, no policy engine installed (the API server does the work). Namespaces `starfleet` (labelled `environment: production`) and `outpost` (labelled `environment: sandbox`) with the Starfleet workloads; a `scout` Deployment scaled to 8 replicas so a replica limit has something to reject. A ConfigMap `replica-limits` in `starfleet` to use as params. No ValidatingAdmissionPolicy yet. -->

<!-- module section-030/module-03 (Module 3) — stub written by /astrona-course-domain-scaffold, prose written by /astrona-course-domain-build. -->
