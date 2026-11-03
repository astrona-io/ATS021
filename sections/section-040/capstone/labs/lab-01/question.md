# Question

Solve this question on: `terminal`

This is the Section 040 capstone: one integrated audit and compliance task, with no step-by-step guidance.

An auditor asks three questions about the `starfleet` namespace. Which identity deleted the Deployment `beacon`? Which Deployments fail a Kyverno policy? Which Deployments violate the Gatekeeper owner label rule? The cluster runs Kyverno with the `ClusterPolicy` objects `require-limits` and `disallow-latest-tag` in `Audit` mode, and Gatekeeper with the Constraint `deployments-need-owner` in `dryrun` mode. They cover the namespaces `starfleet` and `outpost`. The CronJob `deck-cleaner` in `outpost` already deletes and recreates `beacon` every two minutes. API server audit logging is off. The control plane node is a container named `astro-ats-021-capstone-040-control-plane` that you reach with `podman exec` or `docker exec`. Do not repair any workload, and do not change a policy, a Constraint or the CronJob.

1. Turn on audit logging on the API server with this policy. Write it to a file on the control plane node and start the API server with that file. The API server must write the log to `/var/log/kubernetes/audit/audit.log` on the node. Wait until the API server is ready again.

   ```yaml
   apiVersion: audit.k8s.io/v1
   kind: Policy
   omitStages:
     - RequestReceived
   rules:
     - level: None
       nonResourceURLs: ["/healthz*", "/livez*", "/readyz*", "/version"]
     - level: Metadata
       resources:
         - group: ""
           resources: ["secrets"]
     - level: RequestResponse
       resources:
         - group: "apps"
           resources: ["deployments"]
     - level: Metadata
   ```

2. Create a ConfigMap named `auditor-answers` in the namespace `starfleet` with these four keys:
   - `deleted-by`: the user name of the caller in an audit event that shows a successful `delete` of the Deployment `beacon` in `starfleet`.
   - `deletion-audit-id`: the `auditID` of that same event.
   - `kyverno-failing`: the Deployments that fail at least one Kyverno policy, in the form `namespace/name`, separated by commas. Use only Deployments, not ReplicaSets or pods.
   - `owner-label`: the Deployments that Gatekeeper lists as violations of the Constraint `deployments-need-owner`, in the same form.

`kubectl` already points at the cluster. The kubelet needs some time to start the new API server pod, and `kubectl` fails while it restarts. Run a command again if it fails. The deletion of `beacon` appears in the log only after audit logging is on, within about two minutes.
