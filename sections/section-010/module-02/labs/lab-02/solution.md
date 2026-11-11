# Solution

Pin each mode independently. Enforce rejects unsafe Pod requests, warn returns a client warning, and audit adds annotations to audit events. This lab checks the audit label configuration; audit event storage is a separate skill.

Save this as `practice-solution.yaml`:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: starfleet
  labels:
    pod-security.kubernetes.io/enforce: baseline
    pod-security.kubernetes.io/enforce-version: v1.35
    pod-security.kubernetes.io/warn: restricted
    pod-security.kubernetes.io/warn-version: v1.35
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/audit-version: v1.35
```

Apply it:

```sh
kubectl apply -f practice-solution.yaml
```

Check the result:

```sh
kubectl label namespace starfleet pod-security.kubernetes.io/enforce=restricted --overwrite --dry-run=server
kubectl -n starfleet run warn-check --image=curlimages/curl:8.22.0 --dry-run=server
kubectl get namespace starfleet --show-labels
```

Save this as `pod-restricted-check.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: restricted-check
  namespace: starfleet
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: client
    image: curlimages/curl:8.22.0
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop: [ALL]
```

Submit it as a server-side dry run:

```sh
kubectl create --dry-run=server -f pod-restricted-check.yaml
kubectl -n starfleet run privileged-check --image=curlimages/curl:8.22.0 --privileged --dry-run=server
```

The restricted-compliant Pod must be accepted without a Pod Security warning. The privileged Pod must be forbidden by baseline enforcement. Neither dry run stores a Pod.

Use the returned objects and decisions to check every task. A denied request must identify the expected access or policy restriction; a connection failure is not evidence that the restriction works.
