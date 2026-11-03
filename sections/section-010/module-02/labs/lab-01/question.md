# Question

Solve this question on: `terminal`

The `starfleet` namespace has no Pod Security labels. It runs `scout`, `probe` and `shuttle` without a `securityContext`, and a Deployment called `privileged-debug` with a privileged container. The security team wants `starfleet` to enforce the `restricted` Pod Security Standards level, and the three application workloads must keep running.

1. Delete the `privileged-debug` Deployment.

2. Change the Deployments `scout`, `probe` and `shuttle` in `starfleet` so their pods meet the `restricted` level. Each pod must set `runAsNonRoot: true`, a numeric `runAsUser`, `seccompProfile.type: RuntimeDefault`, `allowPrivilegeEscalation: false` and `capabilities.drop: ["ALL"]`. Every replica must be available after the change. Do not delete or scale down a Deployment.

3. Enforce the `restricted` level on `starfleet` with the namespace label `pod-security.kubernetes.io/enforce`. A privileged pod must then be rejected, and `shuttle` must still get an answer from the `scout` Service.

Do not change the `outpost` namespace. `kubectl` already points at the cluster as the cluster administrator.
