---
estimated_duration: 35m
---

# Capstone: Integrate Release Evidence And Signature Admission

One unguided supply chain task combining a Tekton scan gate, retained
software bill of materials (SBOM) evidence, finally reporting and Kyverno
signature admission. The task is in `question.md`; the complete walkthrough
is in `solution.md`.

Tekton 1.17.0, Kyverno 1.19.1, Trivy 0.76.2, cosign 3.1.4 and jq 1.8.2 use
the existing course pins. Scan fixtures deploy only to a zero-replica
Deployment in development. Signature fixtures use the published public key
and server-side admission dry runs. Registry and database access are needed;
there is no private signing key or local registry.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-050/capstone/labs/lab-02
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-050/capstone/labs/lab-02
astrona destroy ats-021-capstone-050-02
```

## Checks

| Script | What it proves |
| --- | --- |
| `validate-vulnerability-gate.sh` | Fresh clean, vulnerable and inventory-error runs prove result gating, finally logs and image-specific evidence retained after run deletion |
| `validate-signature-evidence.sh` | Recorded candidates agree with live cosign verification |
| `validate-production-admission.sh` | Both production namespaces admit signed images and reject unsigned images |
| `validate-namespace-scope.sh` | The policy remains enforced while development and unlabelled namespaces admit both fixtures |

The gate grader compares each saved inventory with a fresh remote Trivy
inventory. It downloads database metadata per run and reads files through
the separate reader pod. All four checks fail before the learner's changes.
Static checks cannot establish controller or registry behavior; the reference
solution and live graders have not been run during authoring.
