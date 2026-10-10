# Choosing The Right Tool

The exam can ask for the same kind of rule with Kyverno, with Gatekeeper or with a ValidatingAdmissionPolicy. A platform team has the same choice every day. This part writes one more CEL policy, a rule about image tags and labels, and uses it to show the two ways a CEL expression can be wrong. It ends with a comparison you can use to pick a tool.

## A second policy with two validations

A policy can hold several entries under `validations`. The API server evaluates all of them, and the request passes only if every one returns `true`. CEL has list macros for checks over all containers: `list.all(c, <condition>)` is `true` when the condition holds for every item.

<!-- astrona:playground:renew -->

Save this as `validatingadmissionpolicy-no-latest-tag.yaml`:

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata:
  name: no-latest-tag
spec:
  failurePolicy: Fail
  matchConstraints:
    resourceRules:
      - apiGroups: ["apps"]
        apiVersions: ["v1"]
        operations: ["CREATE", "UPDATE"]
        resources: ["deployments"]
  validations:
    - expression: >-
        object.spec.template.spec.containers.all(c,
          c.image.contains(':') && !c.image.endsWith(':latest'))
      message: "every container image needs a tag, and the tag must not be latest"
    - expression: "object.spec.template.metadata.labels.team != ''"
      message: "the pod template needs a team label"
```

The first expression rejects an image with no tag (no `:`) or with the tag `latest`. The second one wants a `team` label on the pod template.

Save this as `validatingadmissionpolicybinding-no-latest-tag.yaml`:

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicyBinding
metadata:
  name: no-latest-tag-all
spec:
  policyName: no-latest-tag
  validationActions: ["Deny"]
  matchResources:
    namespaceSelector:
      matchExpressions:
        - key: environment
          operator: Exists
```

This binding uses `matchExpressions` with `Exists`, so it matches every namespace that has an `environment` label, whatever the value: both `starfleet` and `outpost`.

Apply both:

```sh
kubectl apply -f validatingadmissionpolicy-no-latest-tag.yaml
kubectl apply -f validatingadmissionpolicybinding-no-latest-tag.yaml
```

Then try three images in `outpost` with server-side dry runs:

```sh
kubectl -n outpost create deployment beacon --image=nginx:latest --dry-run=server
kubectl -n outpost create deployment beacon --image=nginx --dry-run=server
kubectl -n outpost create deployment beacon --image=ghcr.io/stefanprodan/podinfo:6.15.0 --dry-run=server
```

You should see:

```text
error: failed to create deployment: deployments.apps "beacon" is forbidden: ValidatingAdmissionPolicy 'no-latest-tag' with binding 'no-latest-tag-all' denied request: every container image needs a tag, and the tag must not be latest
error: failed to create deployment: deployments.apps "beacon" is forbidden: ValidatingAdmissionPolicy 'no-latest-tag' with binding 'no-latest-tag-all' denied request: every container image needs a tag, and the tag must not be latest
error: failed to create deployment: deployments.apps "beacon" is forbidden: ValidatingAdmissionPolicy 'no-latest-tag' with binding 'no-latest-tag-all' denied request: expression 'object.spec.template.metadata.labels.team != ''' resulted in error: no such key: team
```

The first two are rejected by the image rule, as planned. The third has a good image, but the message is not the one you wrote. The pod template from `kubectl create deployment` has only the label `app`, so `labels.team` does not exist. Reading a missing key is a **runtime error** in CEL, not `false`, and with `failurePolicy: Fail` the API server rejects the request and prints the error.

The same error blocks every update to an existing Deployment without the label, for example `drifter`. The fix is `has()`, which tests whether a field or key exists without reading it. Change the second validation to:

```yaml
    - expression: "has(object.spec.template.metadata.labels.team)"
      message: "the pod template needs a team label"
```

Apply the changed file:

```sh
kubectl apply -f validatingadmissionpolicy-no-latest-tag.yaml
kubectl -n outpost create deployment beacon --image=ghcr.io/stefanprodan/podinfo:6.15.0 --dry-run=server
```

You should see:

```text
validatingadmissionpolicy.admissionregistration.k8s.io/no-latest-tag configured
error: failed to create deployment: deployments.apps "beacon" is forbidden: ValidatingAdmissionPolicy 'no-latest-tag' with binding 'no-latest-tag-all' denied request: the pod template needs a team label
```

Now the request fails for the right reason, with your message. A Deployment that meets both rules is accepted.

Save this as `deployment-beacon.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: beacon
  namespace: outpost
spec:
  replicas: 1
  selector:
    matchLabels:
      app: beacon
  template:
    metadata:
      labels:
        app: beacon
        team: outpost
    spec:
      containers:
        - name: beacon
          image: ghcr.io/stefanprodan/podinfo:6.15.0
```

Apply it:

```sh
kubectl apply -f deployment-beacon.yaml
```

You should see:

```text
deployment.apps/beacon created
```

## Two kinds of CEL mistakes

A CEL mistake shows up at one of two moments. A **syntax error** is caught when you create the policy: the API server compiles every expression and rejects the object. For example, an expression `object.spec.replicas <= ` with nothing after the operator gives:

```text
The ValidatingAdmissionPolicy "syntax" is invalid: spec.validations[0].expression: Invalid value: "object.spec.replicas <= ": compilation failed: ERROR: <input>:1:25: Syntax error: mismatched input '<EOF>' expecting {'[', '{', '(', '.', '-', '!', 'true', 'false', 'null', NUM_FLOAT, NUM_INT, NUM_UINT, STRING, BYTES, IDENTIFIER}
 | object.spec.replicas <= 
 | ........................^
```

A **type error**, such as a field name that does not exist in the Deployment schema, does not stop the create. The API server stores the policy and writes a warning to `status.typeChecking`. Save this as `validatingadmissionpolicy-typo-replicas.yaml`:

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata:
  name: typo-replicas
spec:
  matchConstraints:
    resourceRules:
      - apiGroups: ["apps"]
        apiVersions: ["v1"]
        operations: ["CREATE", "UPDATE"]
        resources: ["deployments"]
  validations:
    - expression: "object.spec.replica <= 5"
```

Apply it and read its status:

```sh
kubectl apply -f validatingadmissionpolicy-typo-replicas.yaml
kubectl get validatingadmissionpolicy typo-replicas -o jsonpath='{.status.typeChecking.expressionWarnings[0].warning}'
```

You should see:

```text
validatingadmissionpolicy.admissionregistration.k8s.io/typo-replicas created
apps/v1, Kind=Deployment: ERROR: <input>:1:12: undefined field 'replica'
 | object.spec.replica <= 5
 | ...........^
```

The field is `replicas`, not `replica`. The type check runs a few seconds after the apply, so read the status again if it is still empty. Delete the policy when you are done:

```sh
kubectl delete -f validatingadmissionpolicy-typo-replicas.yaml
```

## Picking a tool for a rule

All three tools reject objects at admission, but they do different amounts of work. Use this comparison when a task does not name the tool:

| Question | ValidatingAdmissionPolicy | Kyverno | Gatekeeper |
| --- | --- | --- | --- |
| Extra software in the cluster | None, built into the API server | Kyverno controllers and webhooks | Gatekeeper controllers and webhook |
| Rule language | CEL expressions | YAML patterns, CEL in newer kinds | Rego in a ConstraintTemplate |
| Can change objects | No, validate only | Yes, mutate and generate rules | Mutation is a separate feature |
| Reports on existing objects | No | Yes, PolicyReports from background scans | Yes, audit results in Constraint status |
| Parameters | `paramKind` and `paramRef` | Variables and context in the policy | Constraint `parameters` |
| Failure modes | `Deny`, `Warn`, `Audit` | `Enforce`, `Audit` | `deny`, `dryrun`, `warn` |

A ValidatingAdmissionPolicy fits a short rule on fields of one object, when you want no extra pods, no webhook latency and no webhook outage that can block the API. Kyverno fits when you also need to add defaults, create objects in new namespaces, or show reports on what already runs. Gatekeeper fits a team that already writes Rego, or a rule that needs Rego's richer logic, and its audit reports existing violations too.

You can now write and fix CEL policies, read both kinds of CEL error, and pick between the built-in policy and the two policy engines for a given rule.

## Common pitfalls

> [!WARNING]
> - **Reading a key that may be missing.** `labels.team` on an object without that label is a runtime error; use `has()` first.
> - **Ignoring `status.typeChecking`.** A policy with a wrong field name is stored without error; only the status shows the warning.
> - **Testing only rejected objects.** Always also create one object that must pass, or a broken expression can block everything.
> - **Picking a policy engine for a one-line field check.** If the rule only reads fields of the incoming object, the built-in policy needs nothing installed.
