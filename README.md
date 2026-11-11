# ATS021 — CNPE: Security and Policy Enforcement (Certified Cloud Native Platform Engineer)

[![Liberapay](https://img.shields.io/badge/Liberapay-Support_Astrona.io-F6C915?logo=liberapay&logoColor=black&style=for-the-badge)](https://liberapay.com/Astrona.io)

Course material for the Security and Policy Enforcement domain of the Certified Cloud Native Platform Engineer (CNPE) exam, 15% of the exam. It teaches a platform engineer to lock down a Kubernetes platform from the inside out: least-privilege access with RBAC and Pod Security Admission, mutual TLS and authorization between workloads with Istio and Linkerd, governance with Kyverno, Gatekeeper and ValidatingAdmissionPolicy, audit trails and compliance evidence (API server audit logs, Kyverno policy reports and Gatekeeper audit results), and compliance gates in a Tekton delivery pipeline, SBOM audit evidence, Trivy vulnerability scanning, and signature verification with cosign and Kyverno. Labs check the assigned result through Kubernetes API decisions, mesh requests or generated evidence.

This course covers the **Security and Policy Enforcement** domain of the Certified Cloud Native Platform Engineer (CNPE) exam, **15% of the exam**.

Everything lives under `sections/`. Each section is a set of modules, and each module is:

- a **landing page** (`course.md`) plus, where the subject needs it, ordered **deep-dive parts** (`course-0N-*.md`), woven with hands-on "Try it" checkpoints and Mermaid diagrams;
- an ungraded **playground** for running the examples;
- independent **practice labs** placed after the reading that teaches each task. Focused labs take about 10–15 minutes of learner work, with cluster startup and controller waits listed separately.

Each section ends with a **capstone lab** combining its modules and a knowledge-check quiz. Section 020 also has a second, 30-minute capstone on Linkerd (mesh a namespace, a Server, a repaired MeshTLSAuthentication and a Service-attached HTTPRoute), and Section 050 a second, 35-minute capstone integrating scan evidence and signature admission.

[`astrona.yaml`](astrona.yaml) is the manifest: every section, module, reading, playground, lab and capstone in the order they are meant to be taken.

Everything targets **kind v0.33.0**, **kind_node_image kindest/node:v1.35.8**, **istio 1.31.1**, **linkerd edge-26.10.1**, **kyverno 1.19.1**, **gatekeeper 3.23.1**, **cert-manager 1.21.2**, **tekton-pipelines 1.17.0**, **tkn 0.46.1**, **kyverno-cli-image ghcr.io/kyverno/kyverno-cli:v1.19.1**, **podinfo 6.15.0**, **go-httpbin 2.25.0**, **Trivy 0.76.2**, **cosign 3.1.4**, **jq 1.8.2** on `kind`.

---

## Sections

| Section | Title | Modules | Curriculum item |
| --- | --- | --- | --- |
| [010](sections/section-010) | Access Control For Platform Resources | 2 | Applying RBAC and Security Controls Across Platform Resources |
| [020](sections/section-020) | Secure Service-To-Service Communication | 2 | Configuring Secure Service-to-Service Communication |
| [030](sections/section-030) | Governance With Policy Engines And Admission Control | 3 | Using Policy Engines and Admission Controllers for Governance |
| [040](sections/section-040) | Audit Trails And Compliance Evidence | 2 | Generating Audit Trails and Enforcing Policy Compliance (SBOM, Compliance Reports, etc.) |
| [050](sections/section-050) | Security Checks In The Delivery Pipeline | 3 | Integrating Security Scanning and Compliance Checks into Deployment Pipelines |

---

## How to work through it

1. Open the section's `README.md` for the map.
2. Read each module's `course.md`, then its deep-dive parts in order.
3. Boot the module playground and run the "Try it" checkpoints alongside the text.
4. Complete each registered practice lab after its preparation, then solve the section capstone.
5. Take the section quiz, then the final domain quiz once every section is done.

Use [LAB-COVERAGE.md](LAB-COVERAGE.md) to find the preparation and graders for each task. [COVERAGE-REVIEW.md](COVERAGE-REVIEW.md) records remaining limits. The Pod Security module includes a [three-namespace baseline review lab](sections/section-010/module-02/labs/lab-03): enable warning labels, discover the existing violation, and flag only its namespace.

---

## Support This Project

ATS021 is free training material. If it helped you, consider supporting ongoing work via [Liberapay](https://liberapay.com/Astrona.io).
