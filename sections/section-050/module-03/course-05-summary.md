# Summary

A software bill of materials records the packages detected in an artifact. CycloneDX JSON uses components, while SPDX JSON uses packages. An inventory becomes useful audit evidence when it stays tied to an immutable image digest, a platform and the tool that generated it.

Trivy compares an image or a saved inventory with a vulnerability database. Severity filters, fixed-version filters and ignore files select which findings affect the exit code. The database changes over time, so retain the scan settings and database metadata with the verdict. An inventory is stable evidence of detected contents; a scan is an assessment at a particular time.

A Tekton workspace holds the SBOM and scan report. A Task result carries the small decision that a `when` expression uses to gate deployment. Scanner errors must prevent deployment too. A directory per PipelineRun keeps a later release from overwriting earlier evidence. A completed scan with findings publishes `fail` while its Task succeeds, allowing Tekton to record deployment as skipped. Retained storage outlives a Task pod, but evidence still needs copying outside an environment that will be destroyed.

cosign verifies a signature against a trusted public key and the image digest. Kyverno can repeat that check at admission with an ImageValidatingPolicy. A valid signature proves a trusted key signed the content; it does not prove the content has no vulnerabilities. Inventory, scanning and signature verification each provide a different piece of release evidence.

<!-- astrona:playground:destroy -->
