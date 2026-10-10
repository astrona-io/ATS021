# Produce Compliance Reports From Policy Engines

<!-- astrona:playground -->
> [!NOTE]
> This module has a playground — a throwaway environment to run the commands in.
> ```bash
> astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-040/module-02/playground
> ```

<!-- TODO(build): opening framing — what this module settles, and the contrast that sharpens its boundary. -->

## Learning objectives

- Read a Kyverno PolicyReport and list which workloads fail which rule, with kubectl and with custom columns
- Read Gatekeeper audit results from a Constraint's status and name each violating object
- Pull the audit events for one compliance question (who changed a Deployment, who read a Secret) as evidence
- Choose which source answers a given auditor question (what breaks policy now, what changed, who did it)
- Explain why an Audit-mode policy and Gatekeeper audit report existing objects that admission never saw

## Before you start

<!-- TODO(build): assumed knowledge, and what the playground already provides. -->

## Outline

<!-- TODO(build): each beat below becomes a section of this module (or a deep-dive part via /astrona-course-deep-dive). Delete this Outline section once written. -->

- Compliance evidence a platform can produce without extra tools - policy reports, audit results, audit events
- Kyverno PolicyReports and ClusterPolicyReports - results, summary, background scans
- Gatekeeper audit - Constraint status, totalViolations, the audit interval and its limit
- Turning reports into one answer for an auditor

## Diagrams planned

<!-- TODO(build): mermaid `flowchart` — Existing objects scanned by Kyverno background scan and Gatekeeper audit, plus API requests recorded as audit events, feeding three evidence sources -->

<!-- playground provides: kind cluster with Kyverno 1.19.1 and Gatekeeper 3.23.1 installed. Two Kyverno ClusterPolicies in Audit mode (require resource limits, disallow the latest tag) and one Gatekeeper ConstraintTemplate with a Constraint in dryrun enforcement (require an `owner` label on Deployments), all already producing results. Starfleet workloads in `starfleet`; `probe` has no limits and no `owner` label, and a `legacy-beacon` Deployment uses an image with the `latest` tag (the violations to find). API server audit logging already turned on by the bootstrap with a short Metadata-level policy, so audit events exist to read. No SBOM or vulnerability scanner. -->

<!-- module section-040/module-02 (Module 2) — stub written by /astrona-course-domain-scaffold, prose written by /astrona-course-domain-build. -->
