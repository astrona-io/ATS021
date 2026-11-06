# Prerequisites

- The `astrona` command-line tool, installed and working (`astrona check` passes).
- A container engine that kind can use (Podman or Docker) with about 3 GiB of free memory.
- `kubectl` and `jq`. The lab start downloads the Gatekeeper 3.23.1 release manifest from GitHub and the Helm 4.3.0 archive from `get.helm.sh`, so the machine needs access to both.
- You know what a `ConstraintTemplate` and a Constraint are, how a Rego `violation` rule reads `input.review.object` and `input.parameters`, and what `enforcementAction: deny` does.
- You know the Helm basics from the ATS018 course: a chart directory with `Chart.yaml`, `values.yaml` and `templates/`, how `{{ .Values.name }}` reads a value, and the commands `helm upgrade --install`, `helm list` and `helm history`.

The lab starts a single-node kind cluster (Kubernetes 1.35) with Gatekeeper, the Starfleet workloads in `starfleet` and `outpost`, and the `probe` chart installed as a Helm release. Helm 4.3.0 is installed in `~/.astrona/bin` on the terminal. The start takes a few minutes. The commands are in the README of this folder.
