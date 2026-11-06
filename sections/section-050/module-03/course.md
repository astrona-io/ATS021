# SBOMs And Vulnerability Scanning In The Pipeline

A release can meet every Kubernetes policy and still contain a vulnerable package. A platform needs an inventory of the image, a scan decision tied to that inventory, and proof that the image came from a trusted signer. A **software bill of materials (SBOM)** is a structured list of the software components in an artifact. It lets an auditor ask which release contains a package without rebuilding that release.

You will generate inventories with Trivy, a tool that inspects artifacts and checks them for known vulnerabilities. You will then keep an inventory as pipeline evidence, gate deployment on the scan, and verify signatures with cosign, a tool for signing and verifying artifacts. Kyverno will perform the signature check again at admission, when the API server decides whether to accept an object.

The four parts are **Generate An SBOM As Audit Evidence**, **Use Vulnerability Scan Exit Codes**, **Keep SBOM Evidence In A Tekton Pipeline**, and **Verify Signatures Before Admission**. The audit evidence lab follows the inventory exercise. The vulnerability gate lab follows the retained-evidence exercise: add a scan Task, allow only passing releases to deploy, and preserve inventories across runs. The signature lab follows the verification exercise: check two image signatures, record the result, and enforce the trusted key only in namespaces labelled `environment: production`.

## Learning objectives

After this module you can:

- Generate CycloneDX and SPDX JSON inventories and query package names and versions with `jq`.
- Scan an image or a saved SBOM and explain which findings affect the exit code.
- Write SBOM evidence to a Tekton workspace and use a Task result to gate deployment.
- Verify an image with a public key and require a trusted signature with an `ImageValidatingPolicy`.

## Before you start

You need Deployments, ConfigMaps, service accounts, and the Tekton Task, result, workspace and Pipeline syntax. A **workspace** is storage mounted into Task steps; a **result** is a small named value a Task exposes to a Pipeline. The examples extend a check-and-deploy Pipeline by adding image inventory and scanning.

The playground installs Trivy 0.76.2, cosign 3.1.4, jq 1.8.2, Tekton Pipelines 1.17.0 and Kyverno 1.19.1 on Kubernetes 1.35.8. `trivy`, `cosign` and `jq` run on the terminal. If a command is missing, add `$HOME/.local/bin` to `PATH`. No private signing key is needed.

The `starfleet` namespace contains `scout` using Alpine 3.22.2 and `probe` using Debian 13.1-slim, both pinned by digest. These small inventory workloads run `sleep`; they do not expose an application Service. Each has its own service account. Images are preloaded for Kubernetes. Trivy reads images from their registry, so inventory commands still need internet access. Vulnerability scans also download a database. Signature checks fetch remote signatures and image metadata.

The `pipelines` namespace has the `deploy-inventory` Task, the `pipeline-runner` service account, and the `sbom-evidence` PersistentVolumeClaim. A **PersistentVolumeClaim (PVC)** requests storage whose lifetime is separate from a Task pod. An `evidence-reader` pod mounts it for inspection. No scanning Task, Pipeline or signature policy exists yet.

<!-- astrona:playground -->
