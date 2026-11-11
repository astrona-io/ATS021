# Solution

An SBOM lists software components. A vulnerability scan compares that inventory with advisory data. Inspect the prepared image identities and database timestamps first:

```sh
jq '.metadata.component | {name, version}' /tmp/ats021-sbom-scan/clean.cdx.json /tmp/ats021-sbom-scan/vulnerable.cdx.json
cat /tmp/ats021-sbom-scan/cache/db/metadata.json
```

Run each scan from an interactive shell. Save the exit status immediately, before running another command:

```sh
trivy sbom --cache-dir /tmp/ats021-sbom-scan/cache --skip-db-update --severity HIGH,CRITICAL --ignorefile /dev/null --exit-code 1 --format json --output /tmp/ats021-sbom-scan/clean.scan.json /tmp/ats021-sbom-scan/clean.cdx.json
CLEAN_STATUS=$?
trivy sbom --cache-dir /tmp/ats021-sbom-scan/cache --skip-db-update --severity HIGH,CRITICAL --ignorefile /dev/null --exit-code 1 --format json --output /tmp/ats021-sbom-scan/vulnerable.scan.json /tmp/ats021-sbom-scan/vulnerable.cdx.json
VULNERABLE_STATUS=$?
```

The clean inventory should complete with zero findings and status 0. The vulnerable inventory should complete with findings and status 1. Check that both scans completed and produced readable reports. An error downloading or reading data also prevents a passing decision; do not record that error as a vulnerability count.

Count entries rather than unique identifiers, because one identifier can affect several packages:

```sh
CLEAN_FINDINGS=$(jq '[.Results[]? | .Vulnerabilities[]?] | length' /tmp/ats021-sbom-scan/clean.scan.json)
VULNERABLE_FINDINGS=$(jq '[.Results[]? | .Vulnerabilities[]?] | length' /tmp/ats021-sbom-scan/vulnerable.scan.json)
kubectl -n starfleet create configmap scan-decisions \
  --from-literal=clean-exit-code="$CLEAN_STATUS" \
  --from-literal=vulnerable-exit-code="$VULNERABLE_STATUS" \
  --from-literal=clean-findings="$CLEAN_FINDINGS" \
  --from-literal=vulnerable-findings="$VULNERABLE_FINDINGS"
kubectl -n starfleet get configmap scan-decisions -o yaml
```

Keep the original inventories and database. The grader uses them for independent scans and compares every finding, its package version and severity, then verifies the counts and exit statuses. It does not rely on a fixed historical vulnerability count.
