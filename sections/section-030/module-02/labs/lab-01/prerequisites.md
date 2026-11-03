# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 3 GiB of free memory.
- `kubectl` and `jq`. The lab start downloads the Gatekeeper 3.23.1 release manifest from GitHub, so the machine needs access to GitHub.
- You know what a `ConstraintTemplate` and a Constraint are, the three enforcement actions (`deny`, `dryrun`, `warn`) and where Gatekeeper writes audit results.

The lab starts a single-node kind cluster (Kubernetes 1.35) with Gatekeeper and the Starfleet workloads in `starfleet` and `outpost`. The start takes a few minutes. The commands are in the README of this folder.
