# Overview: Record API Activity With Audit Logging (Playground)

This playground starts a fresh Kubernetes cluster for exploring audit logging. There is no grading. An audit log records requests to the Kubernetes application programming interface (API), including their caller, target and result.

## What's in the box

The single-node kind cluster runs Kubernetes 1.35.8. Audit logging starts disabled. Its control plane node container is `astro-ats-021-playground-040-01-control-plane`. The node includes `jq` 1.7, which selects fields from JavaScript Object Notation (JSON) documents.

| Namespace | Contents |
| --- | --- |
| `starfleet` | `scout` and `probe` backends, the `shuttle` client, and the `scout-db-credentials` Secret |
| `outpost` | The `drifter` client and the `deck-cleaner` CronJob |

A Secret stores sensitive data. A CronJob starts Jobs on a schedule; a Job runs a task to completion. Every two minutes, `deck-cleaner` reads the Secret, deletes `probe` and recreates it. Its service account, the identity its pod uses for API requests, is `system:serviceaccount:outpost:deck-cleaner`. Each other workload also has its own service account.

The application images are preloaded. The scheduled task's logs print response codes for each API action. The actions are deliberate and let you test a real audit policy without extra controllers.

## Helpers

Paste these functions into a terminal with access to the playground's node container. Docker users can replace `podman` with `docker`. `show_audit_flags` reads the startup arguments from the node file. `copy_audit_log` copies a snapshot after you have enabled logging; its optional argument selects the local destination.

```sh
export CONTROL_PLANE=astro-ats-021-playground-040-01-control-plane
show_audit_flags() {
  podman exec "$CONTROL_PLANE" sh -c 'grep -- --audit /etc/kubernetes/manifests/kube-apiserver.yaml || echo "No audit flags configured"'
}
copy_audit_log() {
  podman cp "$CONTROL_PLANE":/var/log/kubernetes/audit/audit.log "${1:-audit.log}"
}
```

Use `show_audit_flags` before and after enabling logging. Use `copy_audit_log` after a request completes. A copied file does not update when the server writes more events. The logs remain on the node until rotation removes them or you destroy the playground.

## Practice tasks

- Write an audit policy that records Secret access at `Metadata`, Deployment changes at `RequestResponse`, and other reads at `None`. Copy it to the node, add the API server flags and mounts, and prove the restart with a real event.
- Pause the CronJob schedule before triggering one Job manually. Find the successful deletion of `probe` and report the identity, namespace, time and response code.
- Compare a Secret read with a Deployment creation. Check whether each event has a request or response body, and explain which policy rule matched.
- Change the policy to keep `RequestReceived`, restart the API server, and group stage events by `auditID`. Explain why event count and request count differ.
- Back up a working static pod manifest outside the watched directory. Introduce a missing policy path, read the startup error through the node, and restore the backup.
