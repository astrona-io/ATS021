# Question

Solve this question on: `terminal`

Two CycloneDX software bills of materials (SBOMs) and a Trivy vulnerability database are prepared at `/tmp/ats021-sbom-scan`. `clean.cdx.json` inventories a package-free hello-world image; `vulnerable.cdx.json` inventories Alpine 3.10.3. Both use immutable image references and the cluster node architecture. No pipeline is needed.

## Tasks

1. Inspect the image identity in each SBOM and the database metadata in `cache/db/metadata.json`. Keep these inputs unchanged.

2. Scan both inventories with Trivy using the prepared cache, `--skip-db-update`, `--severity HIGH,CRITICAL`, `--ignorefile /dev/null` and `--exit-code 1`. Include unfixed findings. Save JSON reports as `clean.scan.json` and `vulnerable.scan.json` in the same directory; record each exit status immediately.

3. Create ConfigMap `scan-decisions` in `starfleet` with keys `clean-exit-code`, `vulnerable-exit-code`, `clean-findings` and `vulnerable-findings`. Each findings value is the number of vulnerability entries across all Results, including separate entries for the same identifier on different packages. Use decimal integer strings.

Use the supplied SBOMs and database. Do not edit inventories, remove findings from a report, update the database, or filter findings by fix availability or an ignore list. A scanner error is not a completed vulnerability decision.

Learner work: about 15 minutes. Cluster startup and controller reconciliation take additional time.
