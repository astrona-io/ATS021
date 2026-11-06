# Prerequisites

Allow 35 minutes. You need to write Tekton Tasks and Pipelines, pass Task
results into `when` expressions, and use `finally` to report execution
status. You also need to generate a software bill of materials (SBOM),
scan images with Trivy, verify public-key signatures with cosign, and
write a Kyverno ImageValidatingPolicy.

The terminal needs registry and vulnerability database access. Bootstrap
installs the pinned tools and controllers and checks database access.
Choose `linux/amd64` or `linux/arm64` to match the node architecture.
Signature fixtures are tested with server-side dry runs and never run.
