# SBOMs And Vulnerability Scanning In The Pipeline

A release can meet every Kubernetes policy and still contain a vulnerable package. A platform needs an inventory of the image, a scan decision tied to that inventory, and proof that the image came from a trusted signer. A **software bill of materials (SBOM)** is a structured list of the software components in an artifact. It lets an auditor ask which release contains a package without rebuilding that release.

You will generate inventories with Trivy, a tool that inspects artifacts and checks them for known vulnerabilities. You will then keep an inventory as pipeline evidence, gate deployment on the scan, and verify signatures with cosign, a tool for signing and verifying artifacts. Kyverno will perform the signature check again at admission, when the API server decides whether to accept an object.

Keep one sentence in mind for this module: **the digest ties the inventory, the scan verdict and the signature to the same image, and each check answers a different question.** The module has four parts, each followed by the lab that uses it:

- **Generate An SBOM As Audit Evidence** inventories the digest-pinned `scout` image in CycloneDX and SPDX, explains how Trivy builds the component tree, and records an index for the auditor. The audit evidence lab follows it.
- **Use Vulnerability Scan Exit Codes** scans the image and the saved inventory, shows the order in which severity, status and ignore filters narrow the findings, and turns the remainder into an exit code.
- **Keep SBOM Evidence In A Tekton Pipeline** writes the inventory and scan report to a retained workspace, exports the verdict as a Task result, and reads the run reasons that tell a skipped deploy from a failed one. The vulnerability gate lab follows it.
- **Verify Signatures Before Admission** verifies the fixture with cosign, then makes Kyverno's `ImageValidatingPolicy` require that key at admission and reads each stage's rejection text. The signature lab follows it and enforces the key only in namespaces labelled `environment: production`.

## Learning objectives

After this module you can:

- Generate CycloneDX and SPDX JSON inventories and query package names and versions with `jq`.
- Explain how Trivy turns an index digest, a platform and an OS package database into a component tree.
- Scan an image or a saved SBOM and explain which findings affect the exit code, and in what filter order.
- Write SBOM evidence to a Tekton workspace and use a Task result to gate deployment.
- Tell a `Succeeded`, `Completed` and `Failed` PipelineRun apart and say what each means for the deploy Task.
- Verify an image with a public key and require a trusted signature with an `ImageValidatingPolicy`.
- Read a Kyverno admission rejection and say which stage of the policy produced it.

## Before you start

You need Deployments, ConfigMaps, service accounts, and the Tekton Task, result, workspace and Pipeline syntax. A **workspace** is storage mounted into Task steps; a **result** is a small named value a Task exposes to a Pipeline. The examples extend a check-and-deploy Pipeline by adding image inventory and scanning.

The playground installs Trivy 0.76.2, cosign 3.1.4, jq 1.8.2, Tekton Pipelines 1.17.0 and Kyverno 1.19.1 on Kubernetes 1.35.8. `trivy`, `cosign` and `jq` run on the terminal. If a command is missing, add `$HOME/.local/bin` to `PATH`. No private signing key is needed.

The `starfleet` namespace contains `scout` using Alpine 3.22.2 and `probe` using Debian 13.1-slim, both pinned by digest. These small inventory workloads run `sleep`; they do not expose an application Service. Each has its own service account. Kubernetes pulls both images from Docker Hub during bootstrap. Trivy reads images from their registry, so inventory commands still need internet access. Vulnerability scans also download a database. Signature checks fetch remote signatures and image metadata.

The `pipelines` namespace has the `deploy-inventory` Task, the `pipeline-runner` service account, and the `sbom-evidence` PersistentVolumeClaim. A **PersistentVolumeClaim (PVC)** requests storage whose lifetime is separate from a Task pod. An `evidence-reader` pod mounts it for inspection. No scanning Task, Pipeline or signature policy exists yet.

<!-- astrona:playground -->
