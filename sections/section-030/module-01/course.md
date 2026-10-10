# Validate, Mutate And Generate With Kyverno

<!-- astrona:playground -->
> [!NOTE]
> This module has a playground — a throwaway environment to run the commands in.
> ```bash
> astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-030/module-01/playground
> ```

<!-- TODO(build): opening framing — what this module settles, and the contrast that sharpens its boundary. -->

## Learning objectives

- Write a validate rule that rejects pods without resource limits in selected namespaces
- Switch a policy between Enforce and Audit and read the effect in a PolicyReport
- Write a mutate rule that adds a default label or securityContext field to matching pods
- Write a generate rule that creates a default-deny NetworkPolicy in every new namespace
- Read a Kyverno admission rejection and name the policy and rule that blocked it
- Exempt one workload from a rule with a PolicyException instead of weakening the policy

## Before you start

<!-- TODO(build): assumed knowledge, and what the playground already provides. -->

## Outline

<!-- TODO(build): each beat below becomes a section of this module (or a deep-dive part via /astrona-course-deep-dive). Delete this Outline section once written. -->

- Kyverno as a validating and mutating webhook; ClusterPolicy versus Policy
- Rule anatomy: match, exclude, validate pattern and deny conditions
- Enforce versus Audit and reading PolicyReports
- Mutate and generate rules
- PolicyException for a documented exemption

## Diagrams planned

<!-- TODO(build): mermaid `sequence` — kubectl apply through the API server to Kyverno's mutating then validating webhook and back -->
<!-- TODO(build): mermaid `flowchart` — One rule's match/exclude selection, then the validate decision, then Enforce versus Audit outcome -->

<!-- playground provides: kind cluster with Kyverno 1.19.1 installed by Helm (admission, background and reports controllers), webhooks ready. Namespaces `starfleet` and `outpost` with the Starfleet workloads; `probe` has no resource limits and `scout` has no `team` label (objects existing policies will flag in background scans). No ClusterPolicy or PolicyException yet. -->

<!-- module section-030/module-01 (Module 1) — stub written by /astrona-course-domain-scaffold, prose written by /astrona-course-domain-build. -->
