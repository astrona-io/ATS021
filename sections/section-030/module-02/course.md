# Enforce Constraints With Gatekeeper And Rego

<!-- astrona:playground -->
> [!NOTE]
> This module has a playground — a throwaway environment to run the commands in.
> ```bash
> astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-030/module-02/playground
> ```

<!-- TODO(build): opening framing — what this module settles, and the contrast that sharpens its boundary. -->

## Learning objectives

- Write a ConstraintTemplate with a Rego violation rule and the parameter schema for its constraint
- Create a Constraint that applies the template to selected kinds and namespaces with parameters
- Switch a Constraint between deny, dryrun and warn with enforcementAction
- Read the audit results in a Constraint's status and list existing violations
- Find the error in a ConstraintTemplate whose Rego does not compile from its status

## Before you start

<!-- TODO(build): assumed knowledge, and what the playground already provides. -->

## Outline

<!-- TODO(build): each beat below becomes a section of this module (or a deep-dive part via /astrona-course-deep-dive). Delete this Outline section once written. -->

- Gatekeeper and OPA; how a ConstraintTemplate creates a new resource kind
- Rego basics needed for a violation rule: input.review.object, parameters, msg
- Constraints: match, parameters, enforcementAction
- Audit - reading totalViolations and violations in the constraint status

## Diagrams planned

<!-- TODO(build): mermaid `flowchart` — ConstraintTemplate creating a CRD, a Constraint of that kind, and the admission and audit paths that use it -->

<!-- playground provides: kind cluster with Gatekeeper 3.23.1 installed by Helm, no Kyverno. Namespaces `starfleet` and `outpost` with the Starfleet workloads; `drifter` uses an image tag `latest` and `probe` has no `team` label, so audit finds violations once a constraint exists. One prepared ConstraintTemplate `k8sbrokenlabels` with a Rego syntax error (to read its status). No working ConstraintTemplate or Constraint yet. -->

<!-- module section-030/module-02 (Module 2) — stub written by /astrona-course-domain-scaffold, prose written by /astrona-course-domain-build. -->
