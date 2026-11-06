# Question

Solve this question on: `terminal`

Gatekeeper 3.23.1 runs in the cluster. The namespace `starfleet` runs `scout` and `shuttle`, and the `probe` team ships its backend as a Helm chart. Helm is a tool that renders chart templates and installs the result as a release. The chart is in `~/resources/probe` on the terminal, and it is already installed as release `probe` in `starfleet` (revision 1, chart version `0.1.0`). The namespace `outpost` runs `drifter`. The platform team now requires two rules in `starfleet`, and the `probe` chart breaks both.

1. Create a `ConstraintTemplate` named `k8sstarfleetworkloadrules` with the constraint kind `K8sStarfleetWorkloadRules`. Its Rego must have two `violation` rules. The first rule reports a Pod that has no label with the name given in the parameter `label`. The second rule reports a Deployment whose `spec.replicas` is below the parameter `minReplicas`. Declare both parameters in the schema (`label` is a string, `minReplicas` is an integer). The template must end with `status.created: true`.

2. Create one Constraint named `starfleet-workload-rules` of kind `K8sStarfleetWorkloadRules` that refuses matching requests. It must match Pods in the core API group and Deployments in the `apps` API group, only in the namespace `starfleet`, with the parameters `label: team` and `minReplicas: 2`. A Pod without the `team` label and a Deployment with one replica must be refused in `starfleet`. A Pod with the `team` label and a Deployment with two replicas must be accepted there. Both must still be accepted in `outpost`.

3. Repair the chart in `~/resources/probe` so that its release satisfies both rules: the pod template must carry the `team` label (the label on the Deployment itself is not enough) and the Deployment must run at least two replicas. Make every change in the chart files, not with `--set` or an extra values file. Raise `version` in `Chart.yaml` to `0.2.0`. Then upgrade the release `probe` in `starfleet` from `~/resources/probe`. When you are done, the release must have the status `deployed` with chart `probe-0.2.0`, and every `probe` pod must be ready and carry the `team` label.

`kubectl` already points at the cluster as the cluster administrator. Helm 4.3.0 is in `~/.astrona/bin`. Gatekeeper takes a few seconds to load a template or a constraint.
