# Record API Activity With Audit Logging

A Deployment has disappeared, but its current state does not say who deleted it. Kubernetes audit logging records requests to the application programming interface (API). An audit event records the caller, the action, the target and the result, so you can answer that question after the request has finished.

Keep one sentence in mind for this module: **the audit policy chooses what to record, and the API server writes the evidence.** You will record Secret access without its contents, record Deployment changes with their bodies, and find the identity that deleted `probe`.

The module has four parts. **Audit Policy Rules, Levels And Stages** writes a policy with ordered rules. **Enable Audit Logging On The API Server** adds the flags and file mounts to the API server's static pod. **Find The Caller And The Change** searches real events and checks which bodies were recorded. **Recover A Failed API Server Restart** diagnoses a missing policy file and restores a working manifest.

## Learning objectives

After this module you can:

- Write an audit policy that records Secret access at `Metadata`, Deployment changes at `RequestResponse`, and drops noisy reads.
- Enable audit logging with the API server's static pod manifest, flags and volumes.
- Confirm the restart and recover when the policy file prevents the API server from starting.
- Find who deleted a Deployment and when, using the audit log.
- Explain an event's level and stage and identify the first policy rule that matched it.

## Before you start

You need namespaces, Deployments, Secrets, service accounts and basic `kubectl` commands. A service account is the identity a pod uses when it calls the Kubernetes API. A Secret is a Kubernetes object that stores sensitive data, such as a password.

Your playground is a single-node kind cluster running Kubernetes 1.35.8. The `starfleet` namespace runs `scout`, `probe` and `shuttle`; `outpost` runs `drifter`. Each workload has its own service account. Audit logging starts disabled. The `deck-cleaner` CronJob in `outpost` reads `scout-db-credentials` and deletes and recreates the `probe` Deployment every two minutes.

A CronJob creates a Job on a schedule; a Job runs pods until its task completes. The `deck-cleaner` service account has permission to perform those actions in `starfleet`. Its activity is deliberate: you will find it in the log.

Use an empty folder on your machine for the files you write. You need access to the playground's node container through Podman; Docker users can replace `podman` with `docker`. These commands target only `astro-ats-021-playground-040-01-control-plane`. The node includes `jq`, a command that selects fields from JavaScript Object Notation (JSON) documents. The examples copy the log to your machine, where you also need `jq`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
