# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 4 GiB of free memory.
- `kubectl` and `jq`. The lab start downloads the Kyverno 1.19.1 and Gatekeeper 3.23.1 release manifests from GitHub, so the machine needs access to GitHub.
- You can write a Kyverno `ClusterPolicy` with a `validate` rule, a Gatekeeper Constraint, and a `ValidatingAdmissionPolicy` with its binding, and you know what `Enforce`, `deny` and `Deny` do.

The lab starts a single-node kind cluster (Kubernetes 1.35) with Kyverno, Gatekeeper and the Starfleet workloads in `starfleet` and `outpost`. The start takes several minutes. The commands are in the README of this folder.
