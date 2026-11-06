# Produce Compliance Reports From Policy Engines

An auditor asks which workloads in `starfleet` break the platform's policies today. The API server cannot answer that from the objects alone, because it does not remember which rules those objects were checked against. Two policy engines, Kyverno and Gatekeeper, keep that evidence in Kubernetes objects. The API server audit log keeps a third kind of evidence: who changed what.

Keep one sentence in mind for this module: **a policy report says what breaks a rule now, and an audit event says who changed it and when.** You will read both kinds of evidence from a cluster that has already produced them, and you will see why they contain objects that admission never checked.

The module has three parts. **Read Kyverno Policy Reports** lists failing workloads per rule with `kubectl`, custom columns and `jq`. **Read Gatekeeper Audit Results** reads the violations in a Constraint status and explains the audit interval and its limit. **Answer An Auditor With The Right Evidence** pulls audit events for one question and matches each kind of question to its source, including a software bill of materials (SBOM) for image package contents.

## Learning objectives

After this module you can:

- Read a Kyverno `PolicyReport` and list which workloads fail which rule, with `kubectl` and with custom columns.
- Read Gatekeeper audit results from a Constraint's `status` and name each violating object.
- Pull the audit events for one compliance question (who changed a Deployment, who read a Secret) as evidence.
- Choose which source answers a given auditor question: what breaks policy now, what changed, who did it.
- Explain why an `Audit`-mode policy and the Gatekeeper audit report existing objects that admission never saw.

## Before you start

You need `kubectl`, namespaces, Deployments and labels. You also need the idea of a policy engine: software that checks objects against rules. An admission controller is code in the API server that checks an object before the API server stores it. An object created before a policy existed never went through that check.

Your playground is a single-node kind cluster running Kubernetes 1.35.8 with Kyverno 1.19.1 and Gatekeeper 3.23.1. The `starfleet` namespace runs `scout`, `probe`, `shuttle` and `legacy-beacon`. The `outpost` namespace runs `drifter`. Two Kyverno `ClusterPolicy` objects (`require-limits` and `disallow-latest-tag`) run in `Audit` mode. One Gatekeeper Constraint (`deployments-need-owner`) runs with enforcement action `dryrun`. None of them blocks anything.

On purpose, `probe` has no resource limits and no `owner` label. `legacy-beacon` uses an image with the `latest` tag and has no `owner` label. These are the violations you will find. API server audit logging is on, with a short policy that records every request at the `Metadata` level. You read the log through the control plane node container, `astro-ats-021-playground-040-02-control-plane`, with Podman; Docker users can replace `podman` with `docker`. You also need `jq`, a command that selects fields from JavaScript Object Notation (JSON) documents, on your machine.

The hands-on work reads policy reports, Constraint status and audit events. A software bill of materials records image package contents, a fourth evidence source to choose when the auditor asks what software shipped.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
