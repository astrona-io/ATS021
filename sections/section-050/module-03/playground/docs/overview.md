# Explore SBOMs, Scanning And Signatures

A software bill of materials (SBOM) records an artifact's detected software
components. This playground has two small inventory workloads in
`starfleet`: `scout` on Alpine 3.22.2 and `probe` on Debian 13.1-slim. Both use
immutable digests and their own service accounts. They run sleep processes;
there is no application Service to call.

Trivy 0.76.2, cosign 3.1.4 and jq 1.8.2 are installed on the terminal. Add
`$HOME/.local/bin` to `PATH` if needed. Trivy fetches images from registries
for analysis; Kubernetes preloading does not populate Trivy's cache.
Vulnerability scanning needs a database download, and signatures need
registry access.

Tekton Pipelines 1.17.0 and Kyverno 1.19.1 are installed. The `pipelines`
namespace has the `deploy-inventory` Task, a `pipeline-runner` service
account that can patch only `scout`, and the `sbom-evidence` storage claim.
The `evidence-reader` pod mounts that storage at `/evidence`. No scan Task,
Pipeline or ImageValidatingPolicy exists yet.

The public test key is at `/tmp/ats021-050-03-keys/audit-signing.pub`. It
verifies a published test image. It grants no signing authority and is
unsuitable as a production trust key.

Try comparing package inventories, changing the scan severity filter, and
inspecting TaskRun results beside their retained reports. Test signature
admission with server-side dry runs. Copy evidence off the volume before
removing the playground.
