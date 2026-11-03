# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 3 GiB of free memory.
- `kubectl` and `jq`. The lab start script downloads `istioctl` 1.31.1 if it is missing, so the machine needs access to GitHub.
- You know how a `PeerAuthentication` and an `AuthorizationPolicy` work in Istio, and how to send a test request with `kubectl exec`.

The lab starts a single-node kind cluster (Kubernetes 1.35) and installs Istio 1.31.1 with the `minimal` profile. The start takes a few minutes. The commands for the lab are in the README of this folder.
