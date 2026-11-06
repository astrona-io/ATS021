# Prerequisites

You need Kubernetes namespaces, Deployments and PersistentVolumeClaims,
and Tekton Tasks, results, workspaces, Pipelines and PipelineRuns. You
should know how a `when` expression selects a Task and how a scan exit
code differs from a Task result.

Use `kubectl` against the lab cluster. Bootstrap installs Trivy 0.76.2 and
jq 1.8.2 on the terminal; add `$HOME/.local/bin` to `PATH` if needed.
Registry access and vulnerability database downloads need internet access,
both on the terminal and from Task pods. No private registry credentials,
signing keys or external user interface are needed. Allow about 25 minutes.
