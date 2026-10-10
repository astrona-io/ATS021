# Policies And CEL Expressions

A platform team often needs one small rule, such as "no Deployment in production runs more than five replicas". Installing a policy engine for that rule adds pods, webhooks and one more thing that can fail. A ValidatingAdmissionPolicy lets the API server check the rule itself. This part writes that rule, binds it to the production namespaces, and then makes it precise with the variables CEL gives you.

## A policy does nothing without a binding

A ValidatingAdmissionPolicy has two main fields. `matchConstraints` lists the requests the policy may look at (API group, version, operation and resource). `validations` lists CEL expressions; each one must return `true`, or the request fails the check. CEL is a small expression language that the API server evaluates, for example `object.spec.replicas <= 5`.

Start by looking at the object the rule is about.

<!-- astrona:playground:renew -->

```sh
kubectl -n starfleet get deployment scout
```

You should see:

```text
NAME    READY   UP-TO-DATE   AVAILABLE   AGE
scout   8/8     8            8           42s
```

Eight replicas is more than the limit you are about to write. Now write the policy.

Save this as `validatingadmissionpolicy-max-replicas.yaml`:

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata:
  name: max-replicas
spec:
  failurePolicy: Fail
  matchConstraints:
    resourceRules:
      - apiGroups: ["apps"]
        apiVersions: ["v1"]
        operations: ["CREATE", "UPDATE"]
        resources: ["deployments"]
  validations:
    - expression: "object.spec.replicas <= 5"
      message: "a Deployment may run at most 5 replicas"
```

`object` is the object the request wants to store. `message` is the text the API server returns when the expression is `false`. `failurePolicy: Fail` tells the API server to reject the request if the expression cannot be evaluated at all; `Ignore` would let it through.

Apply it:

```sh
kubectl apply -f validatingadmissionpolicy-max-replicas.yaml
```

Then try to raise `scout` to 9 replicas. The `--dry-run=server` flag sends the request through admission but does not store the result:

```sh
kubectl -n starfleet patch deployment scout --type=merge -p '{"spec":{"replicas":9}}' --dry-run=server
```

You should see:

```text
deployment.apps/scout patched
```

The request passed. A ValidatingAdmissionPolicy is only a definition. Nothing is checked until a **ValidatingAdmissionPolicyBinding** connects it to a set of namespaces or objects and says what to do when a check fails.

Save this as `validatingadmissionpolicybinding-max-replicas.yaml`:

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicyBinding
metadata:
  name: max-replicas-production
spec:
  policyName: max-replicas
  validationActions: ["Deny"]
  matchResources:
    namespaceSelector:
      matchLabels:
        environment: production
```

`policyName` names the policy. `matchResources.namespaceSelector` limits the check to namespaces with the label `environment: production`, which is `starfleet` and not `outpost`. `validationActions: ["Deny"]` makes a failed check reject the request.

Apply it:

```sh
kubectl apply -f validatingadmissionpolicybinding-max-replicas.yaml
```

Then change something on `scout` that has nothing to do with replicas, such as a label:

```sh
kubectl -n starfleet label deployment scout tier=backend
```

You should see:

```text
The deployments "scout" is invalid: : ValidatingAdmissionPolicy 'max-replicas' with binding 'max-replicas-production' denied request: a Deployment may run at most 5 replicas
```

The API server rejected a label change. Every UPDATE sends the whole object through admission, and the stored `scout` still has 8 replicas, so `object.spec.replicas <= 5` is `false`. The error names the policy, the binding and the message, which is how you find the rule that blocked a request.

## object, oldObject and request

Rejecting every change to an object that was already over the limit is too strict. The owner of `scout` should be able to add a label, or lower the replica count, without first meeting the new rule. CEL gives you more variables to express that:

- `object`: the object as it will be stored after the request. It is `null` for a DELETE.
- `oldObject`: the stored object before the request. It is `null` for a CREATE.
- `request`: facts about the request, for example `request.operation` (`CREATE`, `UPDATE`) and `request.userInfo.username`.
- `params`: a parameter object, used later in this module.

A `messageExpression` is a CEL expression that builds the error message, so the message can show the real values. It must return a string, so numbers go through `string()`.

Save this as `validatingadmissionpolicy-max-replicas.yaml` (it replaces the first version):

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata:
  name: max-replicas
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
        object.spec.replicas <= 5 ||
        (request.operation == 'UPDATE' && object.spec.replicas <= oldObject.spec.replicas)
      messageExpression: >-
        'Deployment ' + object.metadata.name + ' asks for ' +
        string(object.spec.replicas) + ' replicas; the limit is 5'
```

The expression now reads: the request is fine if the new count is at most 5, or if it is an update that does not raise the count. The `oldObject` check sits behind `request.operation == 'UPDATE'`, so it is never read on a CREATE, where `oldObject` is `null`.

Apply it:

```sh
kubectl apply -f validatingadmissionpolicy-max-replicas.yaml
```

Then try the label again, a raise to 9, and a new Deployment with 7 replicas:

```sh
kubectl -n starfleet label deployment scout tier=backend
kubectl -n starfleet patch deployment scout --type=merge -p '{"spec":{"replicas":9}}'
kubectl -n starfleet create deployment relay --image=ghcr.io/stefanprodan/podinfo:6.15.0 --replicas=7 --dry-run=server
```

You should see:

```text
deployment.apps/scout labeled
The deployments "scout" is invalid: : ValidatingAdmissionPolicy 'max-replicas' with binding 'max-replicas-production' denied request: Deployment scout asks for 9 replicas; the limit is 5
error: failed to create deployment: deployments.apps "relay" is forbidden: ValidatingAdmissionPolicy 'max-replicas' with binding 'max-replicas-production' denied request: Deployment relay asks for 7 replicas; the limit is 5
```

The label change now passes, because 8 is not more than the old 8. The raise to 9 and the new `relay` Deployment fail, and the message shows the requested count. Notice that kubectl reports an update as `is invalid` and a create as `is forbidden`; both are the same policy denying the request.

Bring `scout` under the limit with a patch:

```sh
kubectl -n starfleet patch deployment scout --type=merge -p '{"spec":{"replicas":5}}'
```

You should see:

```text
deployment.apps/scout patched
```

## The scale subresource

There is one more way to change replicas. `kubectl scale` does not update the Deployment object; it writes to the Deployment's `scale` subresource, a separate API path (`deployments/scale`) that holds only the replica count. A rule on `deployments` does not match a request to `deployments/scale`.

Try it:

```sh
kubectl -n starfleet scale deployment scout --replicas=7
kubectl -n starfleet get deployment scout
```

You should see:

```text
deployment.apps/scout scaled
NAME    READY   UP-TO-DATE   AVAILABLE   AGE
scout   5/7     7            5           83s
```

The policy did not see the request, and `scout` now runs 7 replicas. The fix is to add `deployments/scale` to `matchConstraints`. The object of a scale request is a `Scale` object of kind `Scale`, which also has `spec.replicas` and `metadata.name`, so the same expression works for both. The message now uses `object.kind` so it says which kind was checked.

Save this as `validatingadmissionpolicy-max-replicas.yaml` (it replaces the second version):

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata:
  name: max-replicas
spec:
  failurePolicy: Fail
  matchConstraints:
    resourceRules:
      - apiGroups: ["apps"]
        apiVersions: ["v1"]
        operations: ["CREATE", "UPDATE"]
        resources: ["deployments", "deployments/scale"]
  validations:
    - expression: >-
        object.spec.replicas <= 5 ||
        (request.operation == 'UPDATE' && object.spec.replicas <= oldObject.spec.replicas)
      messageExpression: >-
        object.kind + ' ' + object.metadata.name + ' asks for ' +
        string(object.spec.replicas) + ' replicas; the limit is 5'
```

Apply it:

```sh
kubectl apply -f validatingadmissionpolicy-max-replicas.yaml
```

Then scale up and down:

```sh
kubectl -n starfleet scale deployment scout --replicas=8
kubectl -n starfleet scale deployment scout --replicas=3
```

You should see:

```text
The deployments "scout" is invalid: : ValidatingAdmissionPolicy 'max-replicas' with binding 'max-replicas-production' denied request: Scale scout asks for 8 replicas; the limit is 5
deployment.apps/scout scaled
```

The raise is rejected with `Scale scout` in the message, and lowering the count to 3 passes.

You can now write a CEL rule, bind it to production namespaces, let existing objects shrink toward the rule, and cover both paths that change replicas. The limit `5` is still written into the policy three times. The next step is to move it out of the policy so each namespace can have its own value.

## Common pitfalls

> [!WARNING]
> - **Creating a policy without a binding.** The API server stores the policy and checks nothing until a binding names it.
> - **Forgetting `deployments/scale`.** `kubectl scale` and HorizontalPodAutoscalers change replicas through the scale subresource, which a rule on `deployments` does not match.
> - **Reading `oldObject` on a CREATE.** `oldObject` is `null` for a CREATE; guard it with `request.operation == 'UPDATE'`.
> - **Using a number in a `messageExpression` directly.** The message must be a string; wrap numbers in `string()`.
> - **Expecting existing objects to be checked.** A policy checks requests only. An object that broke the rule before the policy existed stays until someone changes it.
