# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 3 GiB of free memory.
- `kubectl`. The lab start downloads the Kyverno 1.19.1 release manifest from GitHub, so the machine needs access to GitHub.
- You can read an image reference (registry, tag, digest) and write a Kyverno `ClusterPolicy` with a `validate` rule and a `namespaceSelector`.

The lab starts a single-node kind cluster (Kubernetes 1.35) with Kyverno and two namespaces. The start takes a few minutes. The commands are in the README of this folder.
