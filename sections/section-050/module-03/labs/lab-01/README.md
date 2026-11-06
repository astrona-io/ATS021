---
estimated_duration: 20m
---
# Generate SBOM Audit Evidence

Inspect two pinned workload images, save a CycloneDX inventory for `scout`,
and record live package answers in a ConfigMap. Three checks compare the
file and answers with fresh inventories from the live Deployment images.
No vulnerability database or pipeline is involved.

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-050/module-03/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-050/module-03/labs/lab-01
astrona destroy ats-021-lab-050-03
```

Author validation is offline only: `astrona validate -c sections/section-050/module-03/labs/lab-01`.
The reference solution is `solution/apply.sh`. Bootstrap installs terminal
CLIs using release checksums and preloads the two workload images through
`config.yaml`. Graders fetch the immutable images remotely and select the
node architecture. Report generation needs registry access but no database.
Built without booting on 2026-11-06; live behavior remains untested.

Offline checks passed for YAML parsing, shell syntax, referenced paths and
unique environment names. `astrona validate` could not inspect the lab:
the sandbox refused its `.maintenance.lock` write. No runtime test ran.
