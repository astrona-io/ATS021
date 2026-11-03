# Question

Solve this question on: `terminal`

The auditors of the `starfleet` namespace need a record of who changes things in the cluster. The API server of this kind cluster has no audit logging. Its control plane node runs as a container named `astro-ats-021-lab-040-01-control-plane`; use `podman exec` or `docker exec` to work on it. A CronJob named `deck-cleaner` in `outpost` is already running. Do not delete it, suspend it or change it, and do not leave the API server broken.

1. Turn on audit logging on the API server. It must write the log to `/var/log/kubernetes/audit/audit.log` on the control plane node, and it must read an audit policy file that you write. Wait until the API server is ready again.

2. The audit policy must follow these rules:
   - Requests for Secrets are recorded at level `Metadata`. The log must never hold a Secret body.
   - Requests for Deployments (API group `apps`) are recorded at level `RequestResponse`.
   - The health check requests `/healthz`, `/livez` and `/readyz` are not recorded.
   - The `RequestReceived` stage is not recorded.
   - Other requests may be recorded at `Metadata`, or not recorded.

3. The `deck-cleaner` CronJob runs every two minutes. When logging is on, one of its runs deletes the Deployment `probe` in `starfleet`. Find that deletion in the audit log. Create a ConfigMap named `probe-deletion` in the namespace `starfleet` with two keys: `user`, the user name of the caller in the event, and `auditID`, the `auditID` of the successful `delete` event.

`kubectl` already points at the cluster. The kubelet needs some time to start the new API server pod, and `kubectl` fails while it restarts. Run a command again if it fails. A change of the policy file takes effect only when the API server restarts.
