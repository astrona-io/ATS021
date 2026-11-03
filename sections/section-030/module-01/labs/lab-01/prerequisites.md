# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 3 GiB of free memory.
- `kubectl` and `jq`. The lab start downloads the Kyverno 1.19.1 release manifest from GitHub, so the machine needs access to GitHub.
- You can write a Kyverno `ClusterPolicy` with a `validate`, a `mutate` and a `generate` rule, and you know the difference between `Enforce` and `Audit`.

The lab starts a single-node kind cluster (Kubernetes 1.35) with Kyverno and the Starfleet workloads in `starfleet` and `outpost`. The start takes a few minutes. The commands are in the README of this folder.
