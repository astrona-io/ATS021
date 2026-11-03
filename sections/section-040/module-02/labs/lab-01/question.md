# Question

Solve this question on: `terminal`

An auditor asks which workloads break the platform's policies, and who scaled `relay`. The cluster runs Kyverno with two `ClusterPolicy` objects in `Audit` mode (`require-limits` and `disallow-latest-tag`) and Gatekeeper with the Constraint `deployments-need-owner` in `dryrun` mode. The policies cover the namespaces `starfleet` and `outpost`. API server audit logging is on. The log is the file `/var/log/kubernetes/audit/audit.log` on the control plane node, a container named `astro-ats-021-lab-040-02-control-plane` that you reach with `podman exec` or `docker exec`. Do not repair any workload, and do not change a policy, a Constraint or the audit logging. Only report what the evidence shows.

Create a ConfigMap named `auditor-answers` in the namespace `starfleet` with these five keys:

1. `require-limits`: the Deployments that fail the Kyverno policy `require-limits`, in the form `namespace/name`, separated by commas. Use only Deployments, not ReplicaSets or pods.

2. `disallow-latest-tag`: the Deployments that fail the Kyverno policy `disallow-latest-tag`, in the same form.

3. `owner-label`: the Deployments that Gatekeeper lists as violations of the Constraint `deployments-need-owner`, in the same form.

4. `relay-scaled-by`: the user name of the caller that scaled the Deployment `relay` in `starfleet`, as the API server recorded it for the successful request that changed the `scale` subresource.

5. `source-for-who-scaled`: the source that holds the answer for key 4. Use exactly one of `policy-report`, `constraint-status` or `audit-log`.

`kubectl` already points at the cluster. The reports and the Constraint status can take up to a minute to appear after the start. Run a command again if a list is empty.
