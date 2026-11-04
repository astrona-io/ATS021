# Solution

Solve this lab on `terminal`. This walkthrough shows no captured output, because the values differ in every cluster: the `auditID` and the lists come from your own evidence.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-040/capstone/labs/lab-01
```

The start takes several minutes, because it installs Kyverno and Gatekeeper. Run every `podman exec` command on your own machine. If you use Docker, replace `podman` with `docker`. Three evidence sources hold the answers: the API server audit log (who deleted `beacon`), the Kyverno `PolicyReport` objects and the status of the Gatekeeper Constraint.

Keep this command running in a second host terminal. It grades the lab every few seconds and records nothing:

```sh
astrona submit --watch --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-040/capstone/labs/lab-01
```

Use `--watch` until the end, because a plain `astrona submit` finishes the attempt and deletes the lab. Run the plain command once, in the last step.

## Step 1: Write the audit policy on the node

The audit policy tells the API server which requests to record and at which level. Open a shell on the control plane node:

```sh
podman exec -it astro-ats-021-capstone-040-control-plane bash
```

Create the directories for the policy and the log:

```sh
mkdir -p /etc/kubernetes/audit /var/log/kubernetes/audit
```

Write the policy from the task:

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
  - level: Metadata
EOF
```

The API server uses the first rule that matches a request. The Secret rule stays above the catch-all rule and uses `Metadata`, because `RequestResponse` would write the Secret body into the log.

## Step 2: Add the flags and the volumes to the static pod manifest

The API server runs as a static pod, so you change its manifest file. Copy it, edit the copy and move it back. The kubelet then sees one complete change.

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

The kubelet restarts the API server, and `kubectl` fails for a short time. Leave the node shell with `exit`, then run this command until it works:

```sh
kubectl get --raw=/readyz
```

The watch terminal now shows the checks for audit logging, Secret metadata, Deployment bodies and dropped noise passing. The answer checks still fail, because the ConfigMap does not exist yet.

## Step 3: Find who deleted beacon

The `deck-cleaner` CronJob deletes and recreates `beacon` every two minutes. Wait for a run after the API server restarts. Then filter the log on the node for a successful delete of `beacon`:

```sh
podman exec astro-ats-021-capstone-040-control-plane cat /var/log/kubernetes/audit/audit.log \
  | jq -c 'select(.stage == "ResponseComplete" and .verb == "delete" and .objectRef.resource == "deployments" and .objectRef.namespace == "starfleet" and .objectRef.name == "beacon" and .responseStatus.code == 200) | {user: .user.username, auditID: .auditID}'
```

The output is one JSON line for each deletion, with the `user` and the `auditID`. The user is the service account of the CronJob. If there is no line yet, wait one more minute and run the command again.

## Step 4: Read the Kyverno and Gatekeeper evidence

Kyverno writes one `PolicyReport` for each scanned object. Rule autogeneration also checks Deployments and ReplicaSets, so keep only the Deployments with at least one failed result:

```sh
kubectl get policyreport -A -o json \
  | jq -r '.items[] | .scope as $s | select($s.kind == "Deployment") | select(any(.results[]?; .result == "fail")) | "\($s.namespace)/\($s.name)"' \
  | sort -u | paste -sd, -
```

Gatekeeper audit writes its findings to the status of the Constraint. Read the violations:

```sh
kubectl get k8srequiredlabels deployments-need-owner -o json \
  | jq -r '.status.violations[] | select(.kind == "Deployment") | "\(.namespace)/\(.name)"' | sort -u | paste -sd, -
```

Each command prints one comma-separated list. If a list is empty, wait one minute: the scans need time. Do not repair any workload and do not change a policy.

## Step 5: Write the answers

Create the ConfigMap. Replace each placeholder with the value from the steps above:

```sh
kubectl -n starfleet create configmap auditor-answers \
  --from-literal=deleted-by='<USER FROM STEP 3>' \
  --from-literal=deletion-audit-id='<AUDIT-ID FROM STEP 3>' \
  --from-literal=kyverno-failing='<LIST FROM STEP 4, KYVERNO>' \
  --from-literal=owner-label='<LIST FROM STEP 4, GATEKEEPER>'
```

Press Ctrl-C to stop the watch, then run the grader once:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-040/capstone/labs/lab-01
```

All eight checks pass.

## Common mistakes

- A Secret rule at `RequestResponse` writes Secret bodies into the log. The grader fails it.
- A policy file path that does not exist in the pod stops the API server from starting. Check `crictl logs` on the node.
- Listing ReplicaSets or pods in the lists. Use only Deployments, in the form `namespace/name`.
- Fixing the workloads, switching a policy to `Enforce` or changing the Constraint. The last check fails, because the evidence must stay as it is.
- Using an `auditID` or a user name from memory. Copy both from the audit event.
