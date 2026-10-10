# Constraints And Enforcement Actions

A Constraint is the resource that turns a template into a running rule. It chooses the Kubernetes objects to check, passes parameters into Rego, and decides what Gatekeeper does when the rule reports a violation.

## Match and parameters

The template created a kind named `K8sRequiredLabels`. This constraint uses that kind to require the `team` label on pods in the `starfleet` namespace.

<!-- astrona:playground:renew -->

Save this as `constraint-require-team-label.yaml`:

```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
  name: require-team-label
spec:
  enforcementAction: deny
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
    namespaces: ["starfleet"]
  parameters:
    labels: ["team"]
```

The `match` block selects core API pods in `starfleet`. The empty string in `apiGroups` means the core Kubernetes API group, where Pod lives. The `parameters` block is passed to Rego as `input.parameters`.

Apply it and check the action:

```sh
kubectl apply -f constraint-require-team-label.yaml
kubectl get k8srequiredlabels require-team-label
```

You should see:

```text
k8srequiredlabels.constraints.gatekeeper.sh/require-team-label created
NAME                 ENFORCEMENT-ACTION   TOTAL-VIOLATIONS
require-team-label   deny
```

`enforcementAction: deny` means Gatekeeper rejects a matching admission request when Rego returns a violation.

## Deny a bad pod

Create a pod without the required label. It has resource requests and limits so the only policy issue here is the missing label.

Save this as `pod-no-team.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: no-team
  namespace: starfleet
spec:
  serviceAccountName: shuttle
  containers:
    - name: test
      image: curlimages/curl:8.22.0
      command: ["sh", "-c", "sleep 3600"]
      resources:
        requests:
          cpu: 10m
          memory: 16Mi
        limits:
          memory: 32Mi
```

Apply it:

```sh
kubectl apply -f pod-no-team.yaml
```

You should see:

```text
Error from server (Forbidden): error when creating "pod-no-team.yaml": admission webhook "validation.gatekeeper.sh" denied the request: [require-team-label] missing required label: team
```

The message names the webhook, the constraint and the Rego message. Gatekeeper's validating webhook returned `Forbidden`, so the pod was never stored.

Now create a pod that has the label.

Save this as `pod-with-team.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: with-team
  namespace: starfleet
  labels:
    team: starfleet
spec:
  serviceAccountName: shuttle
  containers:
    - name: test
      image: curlimages/curl:8.22.0
      command: ["sh", "-c", "sleep 3600"]
      resources:
        requests:
          cpu: 10m
          memory: 16Mi
        limits:
          memory: 32Mi
```

Apply it, then check its labels:

```sh
kubectl apply -f pod-with-team.yaml
kubectl -n starfleet get pod with-team --show-labels
```

You should see:

```text
pod/with-team created
NAME        READY   STATUS              RESTARTS   AGE   LABELS
with-team   0/1     ContainerCreating   0          0s    team=starfleet
```

## Dryrun and warn

Gatekeeper supports three useful enforcement actions. `deny` blocks the request. `dryrun` records violations in status and audit, but does not block admission. `warn` allows admission and returns a warning to the client.

Change only `enforcementAction` in `constraint-require-team-label.yaml` to `dryrun`, then apply it and try the bad pod again:

```sh
kubectl apply -f constraint-require-team-label.yaml
kubectl get k8srequiredlabels require-team-label
kubectl apply -f pod-no-team.yaml
kubectl -n starfleet get pod no-team --show-labels
```

You should see:

```text
k8srequiredlabels.constraints.gatekeeper.sh/require-team-label configured
NAME                 ENFORCEMENT-ACTION   TOTAL-VIOLATIONS
require-team-label   dryrun               1
pod/no-team created
NAME      READY   STATUS              RESTARTS   AGE   LABELS
no-team   0/1     ContainerCreating   0          0s    <none>
```

The pod is stored even though it violates the rule. The `TOTAL-VIOLATIONS` value may still show the earlier audit count until the next audit run.

Save this as `pod-warned.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: warned
  namespace: starfleet
spec:
  serviceAccountName: shuttle
  containers:
    - name: test
      image: curlimages/curl:8.22.0
      command: ["sh", "-c", "sleep 3600"]
      resources:
        requests:
          cpu: 10m
          memory: 16Mi
        limits:
          memory: 32Mi
```

Change only `enforcementAction` to `warn`, save the constraint file, and apply it. Then create the second unlabeled pod:

```sh
kubectl apply -f constraint-require-team-label.yaml
kubectl get k8srequiredlabels require-team-label
kubectl apply -f pod-warned.yaml
kubectl -n starfleet get pod warned --show-labels
```

You should see:

```text
k8srequiredlabels.constraints.gatekeeper.sh/require-team-label configured
NAME                 ENFORCEMENT-ACTION   TOTAL-VIOLATIONS
require-team-label   warn                 1
Warning: [require-team-label] missing required label: team
pod/warned created
NAME     READY   STATUS              RESTARTS   AGE   LABELS
warned   0/1     ContainerCreating   0          0s    <none>
```

`warn` is useful when you want users to see the policy message before you start blocking requests. It is not enforcement. The object still exists.

You now know how a constraint selects objects, passes parameters and chooses an enforcement action. The missing piece is how Gatekeeper reports existing objects that were created before the constraint existed.

## Common pitfalls

> [!WARNING]
> - **Putting `enforcementAction` in the template.** The action belongs on each Constraint, not on the ConstraintTemplate.
> - **Forgetting that Pod is in the core API group.** Use `apiGroups: [""]` for pods, Services, ConfigMaps and Secrets.
> - **Reading `dryrun` as a failed request.** `dryrun` reports violations but still admits matching objects.
> - **Reading `warn` as enforcement.** `warn` prints a warning and still creates the object.
