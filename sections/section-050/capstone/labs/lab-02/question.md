# Question

Solve this question on: `terminal`

## Scenario

This is the Section 050 supply chain capstone: one integrated task with no
step-by-step guidance. The `starfleet` team needs a release record that
connects the image inventory, the scan decision and the deployment. Its
production namespaces must also reject images without a trusted signature.

Tekton 1.17.0 and Kyverno 1.19.1 are running. Trivy 0.76.2, cosign 3.1.4
and jq 1.8.2 are on the terminal. The Pipeline `pipelines/release-scan-gate`
currently deploys every image. The Tasks `deploy-scanned-release` and
`report-outcome`, service account `scan-runner`, storage and reader pod are
prepared. The deployment target `starfleet/scout-scan` has zero replicas.

The scan and signature fixtures serve different tests. Deploy the scan
fixtures only to the development namespace `starfleet`, keeping zero
replicas. Use the signature fixtures only for admission dry runs in
`starfleet-prod` and `starfleet-canary`, labelled `environment: production`.
No private signing key or local registry is supplied.

## Required end state

1. **Release decision.** The Pipeline accepts `image` and `platform`, with
   workspace `evidence`. Its Task `check` calls `scan-release-image`, whose
   string inputs are `image`, `platform` and `evidence-directory`, and whose
   result is `outcome`. A software bill of materials (SBOM) lists detected
   software components. Generate the supplied image's CycloneDX JSON SBOM
   with Trivy 0.76.2 and scan it for `HIGH,CRITICAL` vulnerabilities,
   including unfixed findings and using no ignore entries. A completed scan
   publishes `pass` or `fail`; both decisions leave `check` successful.
   Registry, inventory and database errors must prevent deployment.

2. **Deployment and reporting.** `deploy` calls `deploy-scanned-release`
   with the scanned image and uses a `when` expression with input
   `$(tasks.check.results.outcome)`, operator `in`, values `[pass]`. The clean
   image updates the Deployment. The vulnerable image leaves it unchanged,
   with `deploy` skipped and no deploy TaskRun. The `finally` Task `report`
   calls the prepared `report-outcome` after clean, blocked and failed
   checks, passing `$(tasks.status)`
   as `pipeline-status` and `$(tasks.check.status)` as `check-status`.
   Keep the prepared report Task so its logs expose both execution statuses.

3. **Retained evidence.** Bind runs to PersistentVolumeClaim (PVC)
   `pipelines/release-scan-evidence`. Pass each PipelineRun name as
   `evidence-directory` and retain `sbom.cdx.json`, `scan.json` and
   `database.json` in that directory at the workspace root. The SBOM must
   identify the full image and contain its actual inventory. The scan
   report must identify the same image and contain only the selected
   severities. Download the database at run time, retain its metadata,
   then scan against that cache with `--skip-db-update`. Both runs' SBOMs
   must remain readable through pod `release-scan-reader` at
   `/evidence/<PipelineRun-name>/sbom.cdx.json` after later runs and after
   the PipelineRuns and their Task pods are deleted.

4. **Signature evidence and admission.** Verify the candidates in
   `starfleet/signature-candidates` using
   `/tmp/ats021-capstone-050-02-signatures/audit-signing.pub`. Use the public
   test fixture's transparency-log exception. Record their complete
   references in ConfigMap `starfleet/signature-audit`, using keys
   `signed-image` and `unsigned-image`. Create ImageValidatingPolicy
   `signed-production`: enforce `Deny`, fail closed, disable background
   evaluation, and select namespaces by `environment: production`.
   Require the supplied key's signature and digest verification for every
   image on Pod creation and update. The signed fixture must be admitted
   and the unsigned fixture denied in both production namespaces. Both
   fixtures must remain admissible in `outpost` (`environment: development`)
   and `outpost-unlabelled` (no environment label).

Use these exact image references; do not replace the prepared candidate
ConfigMaps. Set `platform` to `linux/amd64` or `linux/arm64` for the node.

| Purpose | Image |
| --- | --- |
| Clean scan | `docker.io/library/hello-world@sha256:5e22040d441e5fb3aed38368acbe8486b575d7018df38dbdfbc7311fbb2ef3a9` |
| Vulnerable scan | `docker.io/library/alpine@sha256:c19173c5ada610a5989151111163d28a67368362762534d8a8121ce95cf2bd5a` |
| Signed admission | `ghcr.io/kyverno/test-verify-image@sha256:b31bfb4d0213f254d361e0079deaaebefa4f82ba7aa76ef82e90b4935ad5b105` |
| Unsigned admission | `ghcr.io/kyverno/test-verify-image@sha256:74a98f0e4d750c9052f092a7f7a72de7b20f94f176a490088f7a744c76c53ea5` |

Keep namespace labels, service accounts, permissions, prepared Tasks, reader
pod and storage. Keep the Deployment at zero replicas. Do not hard-code
release images or scan verdicts in the Task or Pipeline.
