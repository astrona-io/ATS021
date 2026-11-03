# Overview: Produce Compliance Reports From Policy Engines (Playground)

This playground starts a fresh Kubernetes cluster for reading compliance evidence. There is no grading. Three sources already hold evidence: Kyverno policy reports, Gatekeeper audit results and Kubernetes API audit events.

## What's in the box

The single-node kind cluster runs Kubernetes 1.35.8 with Kyverno 1.19.1 and Gatekeeper 3.23.1. Its control plane node container is `astro-ats-021-playground-040-02-control-plane`.

| Namespace | Contents |
| --- | --- |
| `starfleet` | `scout`, `probe`, `shuttle` and `legacy-beacon` Deployments |
| `outpost` | The `drifter` Deployment |
| `kyverno` | The Kyverno controllers |
| `gatekeeper-system` | The Gatekeeper controller manager and the audit controller |

Two Kyverno ClusterPolicies run in `Audit` mode: `require-limits` and `disallow-latest-tag`. One Gatekeeper ConstraintTemplate (`k8srequiredlabels`) and one Constraint (`deployments-need-owner`, enforcement action `dryrun`) require an `owner` label on Deployments. None of them blocks a request.

On purpose, `probe` has no resource limits and no `owner` label. `legacy-beacon` uses `docker.io/library/nginx:latest` and has no `owner` label. Those are the violations to find.

The bootstrap also turned on API server audit logging. The policy file is `/etc/kubernetes/audit/audit-policy.yaml` on the node. It records every request at the `Metadata` level, drops health checks and `kube-proxy`, and skips the `RequestReceived` stage. The log is `/var/log/kubernetes/audit/audit.log` on the node.

## Helpers

Docker users can replace `podman` with `docker`. `read_audit_log` prints the audit log from the node. Pipe it to `jq`, which the node and most machines can run.

```sh
export CONTROL_PLANE=astro-ats-021-playground-040-02-control-plane
read_audit_log() {
  podman exec "$CONTROL_PLANE" cat /var/log/kubernetes/audit/audit.log
}
```

## Practice tasks

- List the failing results in all PolicyReports with `kubectl get policyreport -A`, then with custom columns that show the policy, rule, result and resource name.
- Read `kubectl get k8srequiredlabels deployments-need-owner -o yaml` and name every Deployment in `status.violations`.
- Change `probe` so it has limits and an `owner` label. Wait for the next background scan and audit run, and watch both reports change.
- Create a new Deployment without an `owner` label. Check that admission accepts it, and find when each engine reports it.
- Use `read_audit_log` and `jq` to find who deleted or scaled a Deployment, and who read a Secret.
