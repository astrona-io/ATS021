# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 3 GiB of free memory. You also use it to open a shell on the control plane node container with `podman exec` or `docker exec`.
- `kubectl` and `jq`.
- You can write an audit policy with `level`, `resources`, `nonResourceURLs` and `omitStages`, and you can edit the `kube-apiserver` static pod manifest at `/etc/kubernetes/manifests/kube-apiserver.yaml`.

The lab starts a single-node kind cluster (Kubernetes 1.35) with the Starfleet workloads in `starfleet` and `outpost`. The start takes about a minute. The commands are in the README of this folder.
