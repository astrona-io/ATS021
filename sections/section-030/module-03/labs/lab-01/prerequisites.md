# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 2 GiB of free memory.
- `kubectl` and `jq`.
- You can write a `ValidatingAdmissionPolicy` with a CEL expression, bind it with a `ValidatingAdmissionPolicyBinding`, and you know the validation actions `Deny`, `Warn` and `Audit`.

The lab starts a single-node kind cluster (Kubernetes 1.35) with the Starfleet workloads in `starfleet` and `outpost`. No policy engine is installed. The commands are in the README of this folder.
