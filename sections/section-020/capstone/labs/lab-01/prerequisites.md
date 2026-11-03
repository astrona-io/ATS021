# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 3 GiB of free memory.
- `kubectl` and `jq`. The lab start script downloads `istioctl` 1.31.1 if it is missing, so the machine needs access to GitHub.
- You can require mTLS with a `PeerAuthentication`, write `ALLOW` policies with `principals` and `namespaces`, and find a workload that has no sidecar.

The capstone starts a single-node kind cluster (Kubernetes 1.35) and installs Istio 1.31.1 with the `minimal` profile. The start takes a few minutes. The commands are in the README of this folder.
