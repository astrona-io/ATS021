---
estimated_duration: 15m
---

# Scan Saved Inventories And Record The Decision

Two CycloneDX software bills of materials (SBOMs) and a Trivy vulnerability database are prepared at `/tmp/ats021-sbom-scan`. `clean.cdx.json` inventories a package-free hello-world image; `vulnerable.cdx.json` inventories Alpine 3.10.3. Both use immutable image references and the cluster node architecture. No pipeline is needed.

Allow about 15 minutes of learner work, plus startup and reconciliation.

```sh
astrona run -c sections/section-050/module-03/labs/lab-04
astrona submit -c sections/section-050/module-03/labs/lab-04
astrona destroy ats-021-lab-050-03-04
```

The task is in [question.md](question.md), with a [reference walkthrough](solution.md). Authors run `astrona validate -c sections/section-050/module-03/labs/lab-04` and `astrona test -c sections/section-050/module-03/labs/lab-04`. The lifecycle checks the unfinished state before applying the reference solution.

- Reports and recorded decisions match independent scans of both prepared inventories.
