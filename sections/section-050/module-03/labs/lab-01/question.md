# Question

Solve this question on: `terminal`

## Scenario

An auditor needs a package inventory for the images running in `starfleet`.
The Deployments `scout` and `probe` each run one container and use immutable
image digests. Trivy and jq are installed on the terminal. Registry access
is available. No vulnerability scan or pipeline is required.

## Tasks

1. **Save the inventory.** Generate a CycloneDX JSON software bill of
   materials (SBOM) for the live image of Deployment `scout` in `starfleet`.
   Use the cluster node's Linux architecture. Save the complete inventory,
   including its image metadata and all components, on the terminal at
   `/tmp/ats021-050-03-audit/scout.cdx.json`.
2. **Record the package version.** Create ConfigMap `sbom-audit` in
   `starfleet`. Set its data key `scout-busybox-version` to the installed
   version of package `busybox` in the live `scout` image.
3. **Find the package owners.** Inspect both live images, for `scout` and
   `probe`. Set the same ConfigMap's data key `bash-deployments` to the
   names of the Deployments whose image contains package `bash`. Use a
   sorted, comma-separated list without spaces, or a single name if only
   one matches. Keep both Deployments available, with one replica each.

Keep the workload images and their service accounts unchanged. Do not
replace packages, edit an SBOM to change its inventory, or use a vulnerability
report as the package inventory.
