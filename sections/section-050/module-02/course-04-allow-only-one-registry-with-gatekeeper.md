# Allow Only One Registry With Gatekeeper

The exam gives the same task to candidates who use different policy engines, so you must be able to write the registry rule in Gatekeeper as well. Gatekeeper works differently from Kyverno. You write the rule once as Rego code in a template, and then you create objects of the new kind to switch the rule on with parameters. This part writes the registry rule in that form and shows a difference in what each engine matches.

A **`ConstraintTemplate`** holds the Rego rule and creates a new resource kind. A **Constraint** is an object of that kind. It says where the rule applies (`match`) and gives the parameters. Rego is the policy language of Open Policy Agent (OPA). A Rego rule named `violation` produces a message for every violation.

## Remove the Kyverno policies

Both engines would answer the same request, and you would see the message of one of them. Remove all Kyverno policies, so only Gatekeeper decides:

<!-- astrona:playground:renew -->

```sh
kubectl delete clusterpolicy --all
```

Kyverno deletes the policies it finds. Paste the helper that asks for a dry run, and prove that the cluster admits `nginx:latest` again:

```sh
try_image() {
  kubectl -n "$1" create deployment image-test --image="$2" --dry-run=server
}
try_image starfleet nginx:latest
```

```text
deployment.apps/image-test created (server dry run)
```

## The template and the constraint

The Rego rule reads each container in `input.review.object.spec.containers`. The helper rule `image_allowed` is true when the image starts with one of the strings in `input.parameters.registries`. A container that is not allowed produces a violation with a message.

Save this as `constrainttemplate-k8sallowedregistries.yaml`:

```yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8sallowedregistries
spec:
  crd:
    spec:
      names:
        kind: K8sAllowedRegistries
      validation:
        openAPIV3Schema:
          type: object
          properties:
            registries:
              type: array
              items:
                type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8sallowedregistries

        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          not image_allowed(container.image)
          msg := sprintf("container <%v> uses image <%v>, which is not from an allowed registry %v", [container.name, container.image, input.parameters.registries])
        }

        image_allowed(image) {
          startswith(image, input.parameters.registries[_])
        }
```

Apply the template, wait a few seconds for Gatekeeper to create the new kind, and list the templates:

```sh
kubectl apply -f constrainttemplate-k8sallowedregistries.yaml
kubectl get constrainttemplate
```

```text
constrainttemplate.templates.gatekeeper.sh/k8sallowedregistries created
NAME                   AGE
k8sallowedregistries   8s
```

The constraint below matches Pods in `starfleet` and `starfleet-prod` and allows the registry `ghcr.io/`. The field `enforcementAction: deny` makes the rule reject requests. Save this as `k8sallowedregistries-ghcr-only.yaml`:

```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sAllowedRegistries
metadata:
  name: ghcr-only
spec:
  enforcementAction: deny
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
    namespaces:
      - starfleet
      - starfleet-prod
  parameters:
    registries:
      - "ghcr.io/"
```

Apply it and list the constraint:

```sh
kubectl apply -f k8sallowedregistries-ghcr-only.yaml
kubectl get k8sallowedregistries
```

```text
k8sallowedregistries.constraints.gatekeeper.sh/ghcr-only created
NAME        ENFORCEMENT-ACTION   TOTAL-VIOLATIONS
ghcr-only   deny                 0
```

## Pods are checked, Deployments are not

The constraint matches the kind `Pod`, and Gatekeeper does not generate rules for Deployments from it. Kyverno does. Send the Deployment that Kyverno rejected:

```sh
try_image starfleet nginx:latest
```

```text
deployment.apps/image-test created (server dry run)
```

The API server accepts the Deployment, because the object is not a Pod. Gatekeeper sees the Pod only when the ReplicaSet controller creates it. Send a Pod with a server-side dry run to see the decision:

```sh
kubectl -n starfleet run image-test --image=nginx:latest --dry-run=server
kubectl -n starfleet run image-test --image=ghcr.io/stefanprodan/podinfo:6.15.0 --dry-run=server
```

```text
Error from server (Forbidden): admission webhook "validation.gatekeeper.sh" denied the request: [ghcr-only] container <image-test> uses image <nginx:latest>, which is not from an allowed registry ["ghcr.io/"]
pod/image-test created (server dry run)
```

The webhook name is `validation.gatekeeper.sh`, and the message starts with the Constraint name in brackets. It is one line, and it is the text of the Rego `msg`. Compare it with the Kyverno message, which lists the policy, the rule and the path of the field.

Now create a real Deployment with the bad image and read what happened to it:

```sh
kubectl -n starfleet create deployment bad-nginx --image=nginx:latest
kubectl -n starfleet get deploy bad-nginx
kubectl -n starfleet get events --field-selector reason=FailedCreate
```

```text
deployment.apps/bad-nginx created
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
bad-nginx   0/1     0            0           10s
LAST SEEN   TYPE      REASON         OBJECT                            MESSAGE
5s          Warning   FailedCreate   replicaset/bad-nginx-5b8455bc48   Error creating: admission webhook "validation.gatekeeper.sh" denied the request: [ghcr-only] container <nginx> uses image <nginx:latest>, which is not from an allowed registry ["ghcr.io/"]
```

The Deployment exists, but it has no pods. The ReplicaSet controller tried to create the Pod, and Gatekeeper rejected it. The message is in the events of the ReplicaSet, not in the output of `kubectl create`. Clean up:

```sh
kubectl -n starfleet delete deploy bad-nginx
```

To reject the Deployment at the time of the request, a Gatekeeper template must also match Deployments and read `spec.template.spec.containers`. The exam hint is to read the events when a Deployment shows `0/1` and no error.

## Common pitfalls

> [!WARNING]
> - A Constraint that matches only `Pod` does not reject a Deployment request. The Deployment is stored, and the ReplicaSet records the rejection as a `FailedCreate` event.
> - The Constraint kind exists only after the template is applied and Gatekeeper has created the CRD. If `kubectl apply` of the Constraint says the kind is not found, wait a few seconds and apply again.
> - Without `namespaces` in `match`, the Constraint applies to every namespace Gatekeeper checks. A registry rule can then block system pods that come from other registries when they restart.
> - The prefix `ghcr.io/` ends with a slash. Without the slash, `ghcr.io.example.com/app` would also match.
