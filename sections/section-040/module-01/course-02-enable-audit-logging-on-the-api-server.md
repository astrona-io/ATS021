# Enable Audit Logging On The API Server

An audit policy on the node does nothing until the Kubernetes application programming interface (API) server reads it. The API server also needs a path where it can write the events. In this playground, you set both paths in the static pod manifest and mount the node directories into its container.

A **static pod** is a pod that the node's kubelet starts from a local manifest file. The kubelet is the Kubernetes component that runs pods on a node. When it detects a change in the manifest, it replaces the pod. This briefly interrupts API access, so you must keep a backup you can restore through the node container.

## Edit a copy of the existing manifest

The commands need `audit-policy.yaml` at `/etc/kubernetes/audit/audit-policy.yaml` on the node. They also need the original static pod backup at `/etc/kubernetes/kube-apiserver.before-audit.yaml`. Both were created before changing the API server. Work in the same local folder that holds your copy of `kube-apiserver.yaml`.

<!-- astrona:playground:renew -->

Set the node name in this terminal and check that the policy file exists:

```sh
export CONTROL_PLANE=astro-ats-021-playground-040-01-control-plane
podman exec "$CONTROL_PLANE" test -f /etc/kubernetes/audit/audit-policy.yaml
```

A successful check prints nothing. If it fails, copy your saved policy to that exact path before changing the pod.

Open the local `kube-apiserver.yaml` in your editor. Preserve the existing image, addresses, certificates, probes, arguments and mounts. Add these five entries to the existing `spec.containers[0].command` list:

```yaml
    - --audit-policy-file=/etc/kubernetes/audit/audit-policy.yaml
    - --audit-log-path=/var/log/kubernetes/audit/audit.log
    - --audit-log-maxage=1
    - --audit-log-maxbackup=1
    - --audit-log-maxsize=10
```

The first flag selects the policy; the second selects the log file. The last three limit rotated logs to one day, one retained backup and ten megabytes per file. They keep this playground small. Rotation renames a full log and starts a new one, so older events may live in a backup file rather than the current log.

Add these entries to the existing `spec.containers[0].volumeMounts` list:

```yaml
    - name: audit-policy
      mountPath: /etc/kubernetes/audit
      readOnly: true
    - name: audit-log
      mountPath: /var/log/kubernetes/audit
```

A **volumeMount** exposes a volume at a path inside the container. The policy mount is read-only because the API server only reads it. The log mount must allow writes.

Add these entries to the existing `spec.volumes` list, at pod scope:

```yaml
  - name: audit-policy
    hostPath:
      path: /etc/kubernetes/audit
      type: Directory
  - name: audit-log
    hostPath:
      path: /var/log/kubernetes/audit
      type: DirectoryOrCreate
```

A **hostPath** volume uses a file or directory from the node. Each volume's `name` must match the mount's `name`. `Directory` requires the policy directory to exist; `DirectoryOrCreate` can create the log directory. Both flag paths must be reachable through the mounts inside the API server container.

These fragments are additions to the existing lists, not a complete pod manifest. Save the full edited file as `kube-apiserver.yaml`. Do not replace the original lists with only the new entries.

## Install the file and prove the restart

Stage the complete file outside the manifest directory, then move it into place. This installs a static pod file directly on the node.

Apply it:

```sh
podman cp kube-apiserver.yaml "$CONTROL_PLANE":/tmp/kube-apiserver.yaml
podman exec "$CONTROL_PLANE" mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/kube-apiserver.yaml
```

The kubelet watches `/etc/kubernetes/manifests`. Staging in `/tmp` prevents it from reading a partly copied file. Keep backups outside the watched directory: the kubelet reads manifest files there regardless of a `.backup` suffix.

Then check the result. Allow time for the kubelet to detect the change, and retry the readiness request while the API server restarts:

```sh
sleep 25
until kubectl --request-timeout=5s get --raw=/readyz; do sleep 5; done
printf '\n'
```

You should see something like:

```text
Unable to connect to the server: EOF
Unable to connect to the server: EOF
Unable to connect to the server: EOF
ok
```

The transient errors came from the restart. `ok` means an API server can serve requests. Check the new flags before treating the restart as complete. If the retries continue, interrupt the loop and inspect the container logs through the node; waiting will not fix a missing policy file.

A **mirror pod** is the API representation of a static pod. Read its command list to confirm that the new flags appear:

```sh
kubectl -n kube-system get pod "kube-apiserver-$CONTROL_PLANE" -o jsonpath='{.spec.containers[0].command}' | grep -o -- '--audit[^" ]*'
```

You should see something like:

```text
--audit-policy-file=/etc/kubernetes/audit/audit-policy.yaml
--audit-log-path=/var/log/kubernetes/audit/audit.log
--audit-log-maxage=1
--audit-log-maxbackup=1
--audit-log-maxsize=10
```

The mirror pod can update after the server becomes ready. If the flags are absent, wait a few seconds and check again. A readiness response alone does not prove that auditing is configured; the flags and a real event are the stronger checks.

Save a working backup for recovery:

```sh
podman exec "$CONTROL_PLANE" cp /etc/kubernetes/manifests/kube-apiserver.yaml /etc/kubernetes/kube-apiserver.audit-working.yaml
```

The log belongs to the node filesystem, so it survives an API server container restart. Destroying this playground removes the node and its logs. A production platform also needs a retention and export plan so evidence outlives a failed node.

You have now connected the policy and log files to the API server with flags and matching mounts. The kubelet restarted the static pod, and its mirror pod shows the new arguments. A real request will now prove what the server records.

## Common pitfalls

> [!WARNING]
> - **Adding flags without mounts.** A path on the node is not automatically visible inside the API server container.
> - **Putting volumes under the container.** `volumes` belongs to `spec`; `volumeMounts` belongs to the container.
> - **Replacing the existing command or mount lists.** Keep the original entries, especially certificate paths and startup flags.
> - **Keeping backups in the manifest directory.** The kubelet may treat the backup as another static pod manifest.
> - **Using `kubectl apply` to change the mirror pod.** The kubelet owns the static pod and reads the node's file.
