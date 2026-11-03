# Question

Solve this question on: `terminal`

The platform team installed Kyverno 1.19.1 in the cluster, but no policy exists yet. The namespace `starfleet` runs `scout`, `probe` and `shuttle`. The namespace `outpost` runs `drifter`. Write three Kyverno `ClusterPolicy` resources. Do not change the running workloads, and do not remove or weaken Kyverno.

1. Every container in a pod in `starfleet` must set both `resources.limits.cpu` and `resources.limits.memory`. The API server must refuse a pod that does not, and a Deployment whose pod template does not. The rule must refuse the request, not only record it. It must not apply to `outpost`.

2. Every pod created in `starfleet` must carry a `team` label. When a pod has no `team` label, Kyverno must add `team: unassigned`. When a pod already has one (for example `team: blue`), Kyverno must keep it. Pods in `outpost` must not change.

3. Every new namespace must get a NetworkPolicy named `default-deny` that selects all pods and lists both `Ingress` and `Egress` in `policyTypes`. Skip the system namespaces `kube-system`, `kube-public`, `kube-node-lease`, `kyverno` and `local-path-storage`.

`kubectl` already points at the cluster. Kyverno takes a few seconds to start using a new policy, so run a check again if it still shows the old result. Applying a `kyverno.io/v1` ClusterPolicy prints a deprecation warning. You can ignore it.
