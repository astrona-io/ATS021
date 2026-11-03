# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 3 GiB of free memory.
- `kubectl`. The Tekton command-line tool `tkn` (version 0.46 or later) is useful for reading logs, but `kubectl` is enough. The lab start downloads the Tekton Pipelines 1.17.0 release manifest, so the machine needs internet access.
- You can write a Tekton `Task` with a result, a `Pipeline` with a `when` expression and a `finally` Task, and a `Role` with a `RoleBinding`.

The lab starts a single-node kind cluster (Kubernetes 1.35) with Tekton Pipelines. The start takes a few minutes. The commands are in the README of this folder.
