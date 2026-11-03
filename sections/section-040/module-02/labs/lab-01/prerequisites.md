# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 4 GiB of free memory. Kyverno and Gatekeeper run in the cluster.
- `kubectl` and `jq`. The lab start downloads the Kyverno 1.19.1 and Gatekeeper 3.23.1 manifests from GitHub, so the machine needs access to GitHub.
- You can read a Kyverno `PolicyReport`, the `status` of a Gatekeeper Constraint and an API server audit event with `jq`, and you know which question each source answers.

The lab starts a single-node kind cluster (Kubernetes 1.35). The start takes a few minutes. The commands are in the README of this folder.
