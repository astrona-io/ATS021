# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 4 GiB of free memory. You also use it to open a shell on the control plane node container.
- `kubectl` and `jq`. The lab start downloads the Kyverno 1.19.1 and Gatekeeper 3.23.1 manifests from GitHub, so the machine needs access to GitHub.
- You can turn on audit logging by editing the `kube-apiserver` static pod manifest, search the audit log with `jq`, read a Kyverno `PolicyReport` and read the `status` of a Gatekeeper Constraint.

The lab starts a single-node kind cluster (Kubernetes 1.35). The start takes a few minutes. The commands are in the README of this folder.
