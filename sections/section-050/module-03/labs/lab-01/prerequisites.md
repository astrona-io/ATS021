# Prerequisites

Know how to read a Deployment image reference, inspect a ConfigMap and apply
YAML with kubectl. Understand that an image digest identifies content and
that the node architecture selects a platform-specific image.

The bootstrap installs Trivy 0.76.2 and jq 1.8.2 on the terminal. If needed,
add `$HOME/.local/bin` to `PATH`. Registry access is required for inventories
and for grading. The lab does not need a vulnerability database, cosign,
Tekton or a web interface.
