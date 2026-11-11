# Recover A Failed API Server Restart

A missing audit policy file prevents the Kubernetes application programming interface (API) server from starting. `kubectl` then cannot reach the component it needs to diagnose the problem. You must inspect the failed container through the node and repair the static pod manifest on disk.

A **static pod** is a pod the kubelet runs from a local manifest. The kubelet is the node component that runs Kubernetes pods. It keeps retrying a failed container, but retries cannot create a missing policy file or correct a bad path. This example changes only the disposable playground you created.

## Introduce a missing file path

The node must have a working audit configuration and its backup at `/etc/kubernetes/kube-apiserver.audit-working.yaml`. Keep that backup outside `/etc/kubernetes/manifests`, the directory the kubelet watches. It lets you repair the file even while API access is unavailable.

<!-- astrona:playground:renew -->

Set the node name and verify the backup before making the deliberate mistake:

```sh
export CONTROL_PLANE=astro-ats-021-playground-040-01-control-plane
podman exec "$CONTROL_PLANE" test -f /etc/kubernetes/kube-apiserver.audit-working.yaml
```

A successful check prints nothing. Change the audit policy flag to point at a file that does not exist:

```sh
podman exec "$CONTROL_PLANE" sed -i 's@--audit-policy-file=/etc/kubernetes/audit/audit-policy.yaml@--audit-policy-file=/etc/kubernetes/audit/missing.yaml@' /etc/kubernetes/manifests/kube-apiserver.yaml
```

The kubelet detects the manifest change asynchronously. The old API server may still answer for a short time. Wait for the replacement container to fail before reading the error; this took longer than 25 seconds in the verified run.

## Read the container's own error

`crictl` is the Kubernetes node diagnostic command that talks to a container runtime through the Container Runtime Interface (CRI). It works locally, so it does not need the API server. List API server container identifiers, including stopped containers:

```sh
podman exec "$CONTROL_PLANE" crictl ps -a --name kube-apiserver -q
```

You should see something like:

```text
cbcf8adf2e62b167737b63e381815eaf06422aac808a69782e851747fd4be756
```

The identifiers will differ. `-a` includes stopped containers and `-q` prints only identifiers. Read the most recent container's logs and select the line about the missing file:

```sh
podman exec "$CONTROL_PLANE" sh -c 'container_id=$(crictl ps -a --name kube-apiserver -q | head -n 1); crictl logs "$container_id" 2>&1' | grep 'missing.yaml'
```

You should see something like:

```text
E1012 16:55:43.727385       1 run.go:72] "command failed" err="loading audit policy file: failed to read file path \"/etc/kubernetes/audit/missing.yaml\": open /etc/kubernetes/audit/missing.yaml: no such file or directory"
```

The timestamp and source line may differ, but the error names the exact path the API server tried to open. This is a startup error from the API server, not an admission rejection or a request audit event. If this filter prints nothing, wait and retry: you may still be reading the old running container.

Other failures need the full container log. A policy syntax error requires fixing the policy file. A permission error requires checking the mount and file permissions. A wrong mount name or malformed pod YAML may prevent a container from being created at all, so the kubelet's logs then give the next clue. Work from the reported error rather than changing unrelated flags.

## Restore a known working manifest

Apply the repair by staging the working copy outside the manifest directory and moving it back into place. Then check the readiness endpoint while the kubelet replaces the failed container:

```sh
podman exec "$CONTROL_PLANE" cp /etc/kubernetes/kube-apiserver.audit-working.yaml /tmp/kube-apiserver.repaired.yaml
podman exec "$CONTROL_PLANE" mv /tmp/kube-apiserver.repaired.yaml /etc/kubernetes/manifests/kube-apiserver.yaml
sleep 25
until kubectl --request-timeout=5s get --raw=/readyz; do sleep 5; done
printf '\n'
```

You should see something like:

```text
ok
```

The final `ok` proves the API server serves requests again. The working copy still contains the audit flags and volumes, so recovery preserves audit logging. Restoring the original pre-audit backup would bring the server back with logging disabled instead.

Restarting does not erase the existing log because the `hostPath` volume stores it on the node. It also does not restore events from the outage or correct missing evidence in an earlier snapshot. After recovery, confirm the flags and generate another real request before relying on the new log.

You can now diagnose an API server startup failure without API access, identify the missing path, and restore a working static pod manifest. The same method separates file, policy and mount failures while preserving the evidence already written.

## Common pitfalls

> [!WARNING]
> - **Relying on `kubectl logs` during an API outage.** Read runtime logs through the node while the API server cannot start.
> - **Reading the old container too early.** The kubelet needs time to replace the pod; select the most recent failed attempt.
> - **Keeping no working backup.** Save it outside the watched directory before changing startup configuration.
> - **Restoring the wrong backup.** The pre-audit copy disables audit logging; the working audit copy preserves it.
> - **Making this change on another cluster.** The commands are for the disposable playground's node only.
