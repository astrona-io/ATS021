# Solution

Solve this lab on `terminal`. The output below comes from a real run of this lab.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-030/module-03/labs/lab-01
```

Keep this command running in a second host terminal. It grades the lab every few seconds and records nothing:

```sh
astrona submit --watch --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-030/module-03/labs/lab-01
```

Use `--watch` until the end, because a plain `astrona submit` finishes the attempt and deletes the lab. Run the plain command once, in the last step.

A `ValidatingAdmissionPolicy` has two parts. The policy holds the CEL (Common Expression Language) rule. A `ValidatingAdmissionPolicyBinding` says where the policy applies and what happens on failure. A policy does nothing until a binding names it.

## Step 1: Limit replicas in production

The policy reads the limit from a parameter, so `paramKind` names the kind of the parameter object (a `ConfigMap`). The rule list covers `deployments` and `deployments/scale`, because `kubectl scale` sends its request to the `deployments/scale` subresource. Save this as `validatingadmissionpolicy-replica-limit.yaml`:

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata:
  name: replica-limit
spec:
  failurePolicy: Fail
  paramKind:
    apiVersion: v1
    kind: ConfigMap
  matchConstraints:
    resourceRules:
      - apiGroups: ["apps"]
        apiVersions: ["v1"]
        operations: ["CREATE", "UPDATE"]
        resources: ["deployments", "deployments/scale"]
  validations:
    - expression: "object.spec.replicas <= int(params.data.maxReplicas)"
      messageExpression: >-
        object.kind + ' ' + object.metadata.name + ' asks for ' +
        string(object.spec.replicas) + ' replicas; the limit is ' + params.data.maxReplicas
```

Apply it:

```sh
kubectl apply -f validatingadmissionpolicy-replica-limit.yaml
```

The `Deny` binding applies the policy to every namespace with the label `environment: production`. The `paramRef` names the ConfigMap and its namespace. Save this as `validatingadmissionpolicybinding-replica-limit-production.yaml`:

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicyBinding
metadata:
  name: replica-limit-production
spec:
  policyName: replica-limit
  validationActions: ["Deny"]
  paramRef:
    name: replica-limits
    namespace: starfleet
    parameterNotFoundAction: Deny
  matchResources:
    namespaceSelector:
      matchLabels:
        environment: production
```

Apply it:

```sh
kubectl apply -f validatingadmissionpolicybinding-replica-limit-production.yaml
```

Wait about ten seconds. Then send a Deployment with 6 replicas, a Deployment with 5 replicas, a scale to 9 and a patch to 9. All requests use `--dry-run=server`, so nothing is stored:

```sh
kubectl -n starfleet create deployment big --image=ghcr.io/stefanprodan/podinfo:6.15.0 --replicas=6 --dry-run=server
kubectl -n starfleet create deployment ok --image=ghcr.io/stefanprodan/podinfo:6.15.0 --replicas=5 --dry-run=server
kubectl -n starfleet scale deployment scout --replicas=9 --dry-run=server
kubectl -n starfleet patch deployment scout -p '{"spec":{"replicas":9}}' --dry-run=server
```

You should see:

```text
error: failed to create deployment: deployments.apps "big" is forbidden: ValidatingAdmissionPolicy 'replica-limit' with binding 'replica-limit-production' denied request: Deployment big asks for 6 replicas; the limit is 5
deployment.apps/ok created (server dry run)
The deployments "scout" is invalid: : ValidatingAdmissionPolicy 'replica-limit' with binding 'replica-limit-production' denied request: Scale scout asks for 9 replicas; the limit is 5
The deployments "scout" is invalid: : ValidatingAdmissionPolicy 'replica-limit' with binding 'replica-limit-production' denied request: Deployment scout asks for 9 replicas; the limit is 5
```

The API server rejects the three requests above the limit and accepts the one at the limit. The message for `kubectl scale` starts with `Scale scout`, which shows that the `deployments/scale` rule ran.

The watch terminal now shows the check `replica-limit-denied-in-production` passing. The watch terminal still shows `over-limit-deployment-can-shrink` failing, and the next step shows why.

## Step 2: Allow a request that does not raise the count

`scout` runs 8 replicas, which is already above the limit. Try to lower it to 6, and to change only a label:

```sh
kubectl -n starfleet scale deployment scout --replicas=6 --dry-run=server
kubectl -n starfleet label deployment scout tier=edge --dry-run=server
```

You should see:

```text
The deployments "scout" is invalid: : ValidatingAdmissionPolicy 'replica-limit' with binding 'replica-limit-production' denied request: Scale scout asks for 6 replicas; the limit is 5
The deployments "scout" is invalid: : ValidatingAdmissionPolicy 'replica-limit' with binding 'replica-limit-production' denied request: Deployment scout asks for 8 replicas; the limit is 5
```

Both requests are rejected, but they do not raise the count. The rule must accept an `UPDATE` when the new count is not higher than the old count. The CEL variable `oldObject` holds the object before the change. Save the policy again as `validatingadmissionpolicy-replica-limit.yaml`, with the new `expression`:

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata:
  name: replica-limit
spec:
  failurePolicy: Fail
  paramKind:
    apiVersion: v1
    kind: ConfigMap
  matchConstraints:
    resourceRules:
      - apiGroups: ["apps"]
        apiVersions: ["v1"]
        operations: ["CREATE", "UPDATE"]
        resources: ["deployments", "deployments/scale"]
  validations:
    - expression: >-
        object.spec.replicas <= int(params.data.maxReplicas) ||
        (request.operation == 'UPDATE' && object.spec.replicas <= oldObject.spec.replicas)
      messageExpression: >-
        object.kind + ' ' + object.metadata.name + ' asks for ' +
        string(object.spec.replicas) + ' replicas; the limit is ' + params.data.maxReplicas
```

Apply it:

```sh
kubectl apply -f validatingadmissionpolicy-replica-limit.yaml
```

Wait about ten seconds and repeat the three requests:

```sh
kubectl -n starfleet scale deployment scout --replicas=6 --dry-run=server
kubectl -n starfleet label deployment scout tier=edge --dry-run=server
kubectl -n starfleet scale deployment scout --replicas=9 --dry-run=server
```

You should see:

```text
deployment.apps/scout scaled (server dry run)
deployment.apps/scout labeled (server dry run)
The deployments "scout" is invalid: : ValidatingAdmissionPolicy 'replica-limit' with binding 'replica-limit-production' denied request: Scale scout asks for 9 replicas; the limit is 5
```

Lowering and relabelling now work, and raising above the limit still fails.

The watch terminal now shows the check `over-limit-deployment-can-shrink` passing.

## Step 3: Warn in sandbox namespaces

A binding with `Deny` and `Warn` together is rejected, so sandbox needs its own binding with `validationActions: ["Warn"]`. Before it exists, `outpost` accepts a large Deployment without any message. Save this as `validatingadmissionpolicybinding-replica-limit-sandbox.yaml`:

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicyBinding
metadata:
  name: replica-limit-sandbox
spec:
  policyName: replica-limit
  validationActions: ["Warn"]
  paramRef:
    name: replica-limits
    namespace: starfleet
    parameterNotFoundAction: Deny
  matchResources:
    namespaceSelector:
      matchLabels:
        environment: sandbox
```

Apply it:

```sh
kubectl apply -f validatingadmissionpolicybinding-replica-limit-sandbox.yaml
```

Wait about ten seconds. Then create a Deployment with 8 replicas in `outpost`:

```sh
kubectl -n outpost create deployment wide --image=ghcr.io/stefanprodan/podinfo:6.15.0 --replicas=8 --dry-run=server
```

You should see:

```text
Warning: Validation failed for ValidatingAdmissionPolicy 'replica-limit' with binding 'replica-limit-sandbox': Deployment wide asks for 8 replicas; the limit is 5
deployment.apps/wide created (server dry run)
```

The API server accepts the request and returns the warning. Press Ctrl-C to stop the watch, then run the grader once:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-030/module-03/labs/lab-01
```

All four checks pass. Clean up:

```sh
astrona destroy ats-021-lab-030-03
```
