# Question

Solve this question on: `terminal`

## Scenario

The `starfleet` team has a Tekton Pipeline named `release-scan-gate` in
`pipelines`. It deploys any supplied image through `deploy-scanned-release`.
Add a vulnerability gate and keep the software bill of materials (SBOM),
a file that lists detected software components, for later runs to read.

Tekton 1.17.0, Trivy 0.76.2 and jq 1.8.2 are installed. The `scan-runner`
service account can patch only the prepared `starfleet/scout-scan`
Deployment. Its replica count is zero: this task checks the deployment
change without starting either fixture image. The `release-scan-evidence`
PersistentVolumeClaim (PVC) provides retained storage. The separate
`release-scan-reader` pod mounts it read-only at `/evidence`.

## Tasks

1. **Add the scan Task.** Create `scan-release-image` in `pipelines`.
   Accept string parameters `image`, `platform` and `evidence-directory`,
   mount a workspace named `evidence`, and publish a result named `outcome`.
   Use Trivy 0.76.2 to generate a CycloneDX JSON inventory of the supplied
   image and scan that image for `HIGH,CRITICAL` vulnerabilities. Include
   findings with no fix; use no ignore entries. A completed scan writes
   exactly `pass` for no selected findings or `fail` for selected findings.
   Both decisions must leave the Task successful. Registry, inventory or
   database errors must prevent deployment.

2. **Gate deployment.** Keep the Pipeline's `image` and `platform`
   parameters and `evidence` workspace. Add a Pipeline Task named `check`
   that calls `scan-release-image` with those inputs. Pass the PipelineRun
   name as `evidence-directory`. Keep the Pipeline Task `deploy`, calling
   `deploy-scanned-release` with the same image parameter. Guard it with a
   `when` expression: input `$(tasks.check.results.outcome)`, operator `in`,
   values `[pass]`. A clean image must update `scout-scan`; a vulnerable
   image must leave it unchanged, with `deploy` listed as skipped and no
   deploy TaskRun.

3. **Retain image-specific evidence.** Bind runs to
   `release-scan-evidence`. For each run, save `sbom.cdx.json`, `scan.json`
   and `database.json` inside a directory named after that PipelineRun at
   the workspace root. The SBOM root must name the full scanned image and
   contain its actual inventory. `scan.json` must identify that image and
   hold the severity-filtered Trivy report. `database.json` must contain
   the metadata of the database used. Download the database at run time,
   then scan with `--skip-db-update` against that cache. Both SBOMs must
   remain readable at `/evidence/<PipelineRun-name>/sbom.cdx.json` in
   `release-scan-reader` after a later run and after Task pods are removed.

Use these two immutable, multi-platform fixtures. Select `linux/amd64` or
`linux/arm64` to match the node architecture. The same references are in
ConfigMap `scan-release-images`; changing that ConfigMap does not change
the images used to assess your work.

| Case | Image |
| --- | --- |
| Clean: static binary on an empty base | `docker.io/library/hello-world@sha256:5e22040d441e5fb3aed38368acbe8486b575d7018df38dbdfbc7311fbb2ef3a9` |
| Vulnerable: end-of-life Alpine 3.10.3 | `docker.io/library/alpine@sha256:c19173c5ada610a5989151111163d28a67368362762534d8a8121ce95cf2bd5a` |

Keep the prepared service accounts, deploy Task, reader pod, storage and
Deployment. Leave the Deployment at zero replicas. Do not hard-code the
verdict or a release image in the Task or Pipeline.
