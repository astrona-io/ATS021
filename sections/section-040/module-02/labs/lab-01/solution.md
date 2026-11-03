# Solution

Three evidence sources hold the answers. Kyverno `PolicyReport` objects answer keys 1 and 2. The Gatekeeper Constraint `status.violations` field answers key 3. The API server audit log answers keys 4 and 5. You read each source, then write the answers to one ConfigMap.

## Step 1: Read the Kyverno policy reports

Kyverno writes one `PolicyReport` for each scanned object. The policies match pods, and Kyverno rule autogeneration also checks Deployments and ReplicaSets, so the reports hold results for all three kinds. Keep only the Deployments:

```sh
kubectl get policyreport -A -o json \
  | jq -r '.items[] | .scope as $s | select($s.kind == "Deployment") | select(any(.results[]?; .policy == "require-limits" and .result == "fail")) | "\($s.namespace)/\($s.name)"' \
  | sort -u
```

The output lists the Deployments that fail `require-limits`. Run the same command with `disallow-latest-tag` in place of `require-limits`. If a list is empty, wait one minute: the background scan needs time after the start.

## Step 2: Read the Gatekeeper audit result

Gatekeeper audit writes its findings to the Constraint status. Read the violations of `deployments-need-owner`:

```sh
kubectl get k8srequiredlabels deployments-need-owner -o json \
  | jq -r '.status.violations[] | select(.kind == "Deployment") | "\(.namespace)/\(.name)"' | sort -u
```

The Constraint audit runs every 60 seconds by default, so `status.violations` can be empty at first.

## Step 3: Find who scaled relay in the audit log

A policy report and a Constraint status say what is wrong now. Only the audit log says who made a change. Filter the log on the control plane node for the successful patch of the `scale` subresource of `relay`:

```sh
podman exec astro-ats-021-lab-040-02-control-plane cat /var/log/kubernetes/audit/audit.log \
  | jq -r 'select(.stage == "ResponseComplete" and .verb == "patch" and .objectRef.resource == "deployments" and .objectRef.subresource == "scale" and .objectRef.namespace == "starfleet" and .objectRef.name == "relay" and .responseStatus.code == 200) | .user.username'
```

The output is the user name of the caller. Use Docker instead of Podman by replacing `podman` with `docker`.

## Step 4: Write the answers

Create the ConfigMap. Replace each placeholder with the comma-separated list or the user name from the steps above:

```sh
kubectl -n starfleet create configmap auditor-answers \
  --from-literal=require-limits='<LIST FROM STEP 1>' \
  --from-literal=disallow-latest-tag='<LIST FROM STEP 1, SECOND POLICY>' \
  --from-literal=owner-label='<LIST FROM STEP 2>' \
  --from-literal=relay-scaled-by='<USER FROM STEP 3>' \
  --from-literal=source-for-who-scaled=audit-log
```

Submit:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-040/module-02/labs/lab-01
```

All checks pass. The value of `source-for-who-scaled` is `audit-log` because policy reports and Constraint status hold no information about the caller of a request.

## Common mistakes

- Listing ReplicaSets or pods in the answers. Use only Deployments, in the form `namespace/name`.
- Fixing the workloads or changing a policy. The answers must match the evidence as it is.
- Using a user name from memory. Copy it from the audit event.
