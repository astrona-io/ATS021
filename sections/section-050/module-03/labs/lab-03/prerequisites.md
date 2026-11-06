# Prerequisites

You need `kubectl`, ConfigMaps and namespace labels. A ConfigMap stores
non-secret key-value strings. An image digest identifies immutable content;
a public key verifies a signature made with the matching private key.

The lab installs cosign 3.1.4 on `terminal` and Kyverno 1.19.1 in Kubernetes
1.35.8. Add `$HOME/.local/bin` to `PATH` if `cosign` is missing. Python 3 and
curl are terminal prerequisites, as in the sibling labs.

The terminal and Kyverno need outbound access to `ghcr.io` for image
metadata and signature lookup. Controller images are preloaded. Candidate
images never run: server-side dry runs exercise admission without pulling
images onto a node. No private signing key or local registry is needed.
