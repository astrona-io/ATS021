# Prerequisites

Read the teaching immediately before this lab. You need to inspect Kubernetes objects, save a YAML manifest and apply it with `kubectl`. This lab starts independently; it does not reuse a previous lab or the playground.

Two CycloneDX software bills of materials (SBOMs) and a Trivy vulnerability database are prepared at `/tmp/ats021-sbom-scan`. `clean.cdx.json` inventories a package-free hello-world image; `vulnerable.cdx.json` inventories Alpine 3.10.3. Both use immutable image references and the cluster node architecture. No pipeline is needed.
