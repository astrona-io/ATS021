# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 3 GiB of free memory.
- `kubectl`. The lab start script downloads the `linkerd` command-line tool (edge-26.10.1), the Gateway API CRDs and the Linkerd manifests, so the machine needs access to GitHub.
- You know how Linkerd's default inbound policy, a `Server`, a `MeshTLSAuthentication` and an `AuthorizationPolicy` work.

The lab starts a single-node kind cluster (Kubernetes 1.35) and installs Linkerd edge-26.10.1. The start takes a few minutes. The commands for the lab are in the README of this folder.
