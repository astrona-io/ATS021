# Solution

The cluster has no audit logging. You write an audit policy file on the control plane node, add flags and volumes to the `kube-apiserver` static pod manifest, wait for the API server to restart, and then read the log to find the deletion of `probe`.

Run every `podman exec` command on your own machine. If you use Docker, replace `podman` with `docker`.

## Step 1: Write the audit policy on the node

The audit policy tells the API server which requests to record and at which level. Open a shell on the control plane node:

```sh
podman exec -it astro-ats-021-lab-040-01-control-plane bash
```

Create the directories for the policy and the log:

```sh
mkdir -p /etc/kubernetes/audit /var/log/kubernetes/audit
```

Write the policy file:

```sh
cat > /etc/kubernetes/audit/audit-policy.yaml <<'EOF'
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
  - level: None
    verbs: ["get", "list", "watch"]
  - level: Metadata
EOF
```

The API server uses the first rule that matches a request. The Secret rule must come before the catch-all rule, and it must use `Metadata`, because `RequestResponse` would write the Secret body into the log. The `omitStages` field drops the `RequestReceived` stage. The `None` rule for `/healthz*`, `/livez*` and `/readyz*` drops the health checks.

## Step 2: Add the flags and the volumes to the static pod manifest

The API server runs as a static pod, so you change its manifest file. Make a copy first, edit the copy, and move it back. This way the kubelet sees one complete change.

```sh
cp /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/kube-apiserver.yaml
```

Edit `/tmp/kube-apiserver.yaml` with `vi`. Add these lines to the `command` list, below `- kube-apiserver`:

```yaml
    - --audit-policy-file=/etc/kubernetes/audit/audit-policy.yaml
    - --audit-log-path=/var/log/kubernetes/audit/audit.log
    - --audit-log-maxage=1
    - --audit-log-maxbackup=1
    - --audit-log-maxsize=10
```

Add these entries to `volumeMounts`:

```yaml
    - mountPath: /etc/kubernetes/audit
      name: audit-policy
      readOnly: true
    - mountPath: /var/log/kubernetes/audit
      name: audit-log
```

Add these entries to `volumes`:

```yaml
  - hostPath:
      path: /etc/kubernetes/audit
      type: Directory
    name: audit-policy
  - hostPath:
      path: /var/log/kubernetes/audit
      type: DirectoryOrCreate
    name: audit-log
```

Move the file back:

```sh
mv /tmp/kube-apiserver.yaml /etc/kubernetes/manifests/kube-apiserver.yaml
```

The kubelet notices the change and restarts the API server. `kubectl` fails for a short time. Leave the node shell with `exit`, then run this command until it works:

```sh
kubectl get --raw=/readyz
```

Submit to see the first checks turn green:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-040/module-01/labs/lab-01
```

The checks for audit logging enabled, Secret metadata, Deployment bodies and dropped noise pass now. The check for the deletion evidence still fails.

## Step 3: Find the deletion of probe

The `deck-cleaner` CronJob runs every two minutes. Wait for a run after the API server restarts. Then filter the log on the node for a successful delete of `probe`:

```sh
podman exec astro-ats-021-lab-040-01-control-plane cat /var/log/kubernetes/audit/audit.log \
  | jq -c 'select(.stage == "ResponseComplete" and .verb == "delete" and .objectRef.resource == "deployments" and .objectRef.name == "probe" and .responseStatus.code == 200) | {user: .user.username, auditID: .auditID}'
```

The output is one JSON line with the `user` and the `auditID` of the event. The `auditID` is different in every cluster, so use the value from your own log. If there is no line yet, wait one more minute and run the command again.

## Step 4: Record the evidence

Create the ConfigMap with the two values from the event. Replace the placeholders:

```sh
kubectl -n starfleet create configmap probe-deletion \
  --from-literal=user='<USER>' \
  --from-literal=auditID='<AUDIT-ID>'
```

Submit again:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-040/module-01/labs/lab-01
```

All five checks pass.

## Common mistakes

- A Secret rule at `RequestResponse` writes Secret bodies into the log. The grader fails it.
- A Deployment rule at `Metadata` records no request body or response body. The grader needs both.
- A policy file path that does not exist in the pod stops the API server from starting. Check `crictl logs` on the node.
- Copy the `auditID` from the event. An ID that is not in the log fails the check.
