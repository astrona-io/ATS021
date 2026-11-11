# Solution

Use the Deployment schema field `replicas`. Guard the optional map key with `has()` before reading its value. A compliant request must pass; rejected requests must return the policy message instead of an evaluation error.

Save this as `practice-solution.yaml`:

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata:
  name: workload-check
spec:
  failurePolicy: Fail
  matchConstraints:
    resourceRules:
    - apiGroups:
      - apps
      apiVersions:
      - v1
      operations:
      - CREATE
      - UPDATE
      resources:
      - deployments
  validations:
  - expression: object.spec.replicas <= 5
    message: replicas must not exceed five
  - expression: has(object.spec.template.metadata.labels.team) && object.spec.template.metadata.labels.team
      != ''
    message: team must be nonempty
---
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicyBinding
metadata:
  name: workload-check
spec:
  policyName: workload-check
  validationActions:
  - Deny
  matchResources:
    namespaceSelector:
      matchLabels:
        kubernetes.io/metadata.name: starfleet
```

Apply it:

```sh
kubectl apply -f practice-solution.yaml
```

Check the result:

```sh
kubectl get validatingadmissionpolicy workload-check -o yaml
kubectl -n starfleet create deployment missing-team --image=ghcr.io/stefanprodan/podinfo:6.15.0 --dry-run=server
kubectl -n outpost create deployment outside-check --image=ghcr.io/stefanprodan/podinfo:6.15.0 --replicas=6 --dry-run=server
```

Save a compliant request as `deployment-team-check.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: team-check
  namespace: starfleet
spec:
  replicas: 5
  selector:
    matchLabels:
      app: team-check
  template:
    metadata:
      labels:
        app: team-check
        team: blue
    spec:
      containers:
      - name: app
        image: ghcr.io/stefanprodan/podinfo:6.15.0
```

Submit it as a server-side dry run:

```sh
kubectl create --dry-run=server -f deployment-team-check.yaml
```

The request must pass. Change replicas to six and repeat; the policy must return `replicas must not exceed five`. Restore five, remove the team label and repeat; the policy must return `team must be nonempty` instead of a CEL evaluation error. A team value of an empty string must produce the same policy message.

Use the returned objects and decisions to check every task. A denied request must identify the expected access or policy restriction; a connection failure is not evidence that the restriction works.
