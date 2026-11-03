# Allow Only One Registry With Kyverno

The first rule a platform team writes about images is the registry: the cluster should run images from one registry that the team trusts, not from any server on the internet. Kyverno, a policy engine that runs as an admission webhook, can enforce this with one `ClusterPolicy`. This part writes the policy and proves it with one rejected and one accepted Deployment.

A Kyverno **`ClusterPolicy`** holds a list of rules. Each rule has a `match` block that selects objects and a `validate` block that checks them. The field `validate.failureAction` decides what a failure does: `Enforce` rejects the request, and `Audit` only records the failure.

## The rule

The policy below matches `Pod` objects in namespaces that carry the label `environment`, which are `starfleet` and `starfleet-prod`. Matching on the namespace label keeps the rule away from system namespaces such as `gatekeeper-system`, whose images come from other registries. The `pattern` says that the `image` of every container must start with `ghcr.io/`. The `*` is a wildcard.

The policy matches the kind `Pod`, not `Deployment`. Kyverno generates the matching rules for Deployments, StatefulSets, DaemonSets, Jobs and CronJobs from the Pod rule. It adds the prefix `autogen-` to the rule name, and you will see that prefix in the rejection message.

<!-- astrona:playground:renew -->

Save this as `clusterpolicy-allowed-registries.yaml`:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: allowed-registries
spec:
  background: true
  rules:
    - name: only-ghcr
      match:
        any:
          - resources:
              kinds:
                - Pod
              namespaceSelector:
                matchExpressions:
                  - key: environment
                    operator: Exists
      validate:
        failureAction: Enforce
        message: "Images must come from ghcr.io."
        pattern:
          spec:
            containers:
              - image: "ghcr.io/*"
```

Apply it:

```sh
kubectl apply -f clusterpolicy-allowed-registries.yaml
```

Kyverno 1.19.1 prints a warning that `kyverno.io/v1` `ClusterPolicy` is deprecated in favour of the `policies.kyverno.io` kinds. The old kind still works, and the warning does not stop the apply. Then check that the policy is ready:

```sh
kubectl get clusterpolicy
```

You should see something like this:

```text
NAME                 ADMISSION   BACKGROUND   READY   AGE   MESSAGE
allowed-registries   true        true         True    8s    Ready
```

## Prove the rule

Paste this helper. It asks the API server, without storing anything, whether a Deployment with the given image is accepted in a namespace:

```sh
try_image() {
  kubectl -n "$1" create deployment image-test --image="$2" --dry-run=server
}
```

First send an image from `docker.io` to `starfleet`:

```sh
try_image starfleet nginx:latest
```

The API server rejects it. The webhook name `validate.kyverno.svc-fail` shows that Kyverno answered:

```text
error: failed to create deployment: admission webhook "validate.kyverno.svc-fail" denied the request: 

resource Deployment/starfleet/image-test was blocked due to the following policies 

allowed-registries:
  autogen-only-ghcr: 'validation error: Images must come from ghcr.io. rule autogen-only-ghcr failed at path /spec/template/spec/containers/0/image/'
```

The message names the policy (`allowed-registries`), the rule (`autogen-only-ghcr`), your own message text and the path of the field that failed. Now send the `podinfo` image from `ghcr.io`:

```sh
try_image starfleet ghcr.io/stefanprodan/podinfo:6.15.0
```

```text
deployment.apps/image-test created (server dry run)
```

The same `nginx:latest` image in the `default` namespace still passes, because that namespace has no `environment` label:

```sh
try_image default nginx:latest
```

```text
deployment.apps/image-test created (server dry run)
```

The registry rule works only where the `match` block selects. The label on the namespace is the switch that turns the policy on for a namespace. A policy that you must prove on both sides, one rejected object and one accepted object, is a policy that you can trust.

The registry rule still admits `ghcr.io/stefanprodan/podinfo:latest`. The next part closes that hole with tag rules.

## Common pitfalls

> [!WARNING]
> - The pattern `ghcr.io/*` matches the start of the string. The reference `nginx:latest` has no registry in the string, so it fails, even though the runtime reads it as `docker.io`. This is the behaviour you want for an allow list.
> - A policy with `failureAction: Audit` accepts the Deployment and only records the failure. If a request that you expect to fail succeeds, read the field first.
> - The rule checks `containers`. Init containers and ephemeral containers have their own fields and need their own pattern.
> - Rejected objects name `autogen-` rules. Search for the rule name without the prefix when you look for the rule in your own policy.
