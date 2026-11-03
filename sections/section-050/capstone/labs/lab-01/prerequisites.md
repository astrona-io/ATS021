# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 4 GiB of free memory, because Tekton Pipelines and Kyverno run together.
- `kubectl`. The Tekton command-line tool `tkn` (version 0.46 or later) is useful for reading logs, but `kubectl` is enough. The lab start downloads the Tekton Pipelines 1.17.0 and Kyverno 1.19.1 release manifests, so the machine needs internet access.
- You can write a Tekton `Task` with a result, a `Pipeline` with a `when` expression and a `finally` Task, a `Role` with a `RoleBinding`, and a Kyverno `ClusterPolicy` with a `namespaceSelector`.

The lab starts a single-node kind cluster (Kubernetes 1.35). The start takes several minutes. The commands are in the README of this folder.
