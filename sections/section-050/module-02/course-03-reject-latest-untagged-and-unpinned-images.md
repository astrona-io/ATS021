# Reject Latest, Untagged And Unpinned Images

A trusted registry does not make an image reference stable. The registry owner, or someone who steals the owner's credentials, can move a tag to different content. This part adds two rules that fix the reference itself: no `latest` and no missing tag everywhere, and a digest in production.

The first rule forbids the references that change by design. The second goes further and forbids every tag in a production namespace, because only a digest always points at the same content. You write both as Kyverno rules, and the digest rule uses the namespace label to apply to `starfleet-prod` only.

## Reject latest and missing tags

One `ClusterPolicy` can hold several rules. The policy below has two. The rule `require-tag` uses the pattern `*:*`: the image string must contain a colon. The rule `disallow-latest` uses the pattern `!*:latest`: the `!` negates the match, so any image that ends in `:latest` fails. A digest contains a colon too (`@sha256:`), so a digest reference passes the first rule.

<!-- astrona:playground:renew -->

Save this as `clusterpolicy-image-tags.yaml`:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: image-tags
spec:
  background: true
  rules:
    - name: require-tag
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
        message: "An image tag is required."
        pattern:
          spec:
            containers:
              - image: "*:*"
    - name: disallow-latest
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
        message: "Using a mutable image tag such as 'latest' is not allowed."
        pattern:
          spec:
            containers:
              - image: "!*:latest"
```

Apply it:

```sh
kubectl apply -f clusterpolicy-image-tags.yaml
```

Paste the helper that asks the API server for a dry run:

```sh
try_image() {
  kubectl -n "$1" create deployment image-test --image="$2" --dry-run=server
}
```

Then send a `latest` tag, a reference with no tag and a pinned tag. All three images come from `ghcr.io`, so the registry is not the reason for any result:

```sh
try_image starfleet ghcr.io/stefanprodan/podinfo:latest
try_image starfleet ghcr.io/stefanprodan/podinfo
try_image starfleet ghcr.io/stefanprodan/podinfo:6.15.0
```

The first two requests fail, each with the message of its own rule. The second request shows that a missing tag fails the `require-tag` rule, and the first shows that `:latest` fails `disallow-latest`:

```text
error: failed to create deployment: admission webhook "validate.kyverno.svc-fail" denied the request: 

resource Deployment/starfleet/image-test was blocked due to the following policies 

image-tags:
  autogen-disallow-latest: 'validation error: Using a mutable image tag such as ''latest'' is not allowed. rule autogen-disallow-latest failed at path /spec/template/spec/containers/0/image/'
error: failed to create deployment: admission webhook "validate.kyverno.svc-fail" denied the request: 

resource Deployment/starfleet/image-test was blocked due to the following policies 

image-tags:
  autogen-require-tag: 'validation error: An image tag is required. rule autogen-require-tag failed at path /spec/template/spec/containers/0/image/'
deployment.apps/image-test created (server dry run)
```

A pinned tag such as `6.15.0` still passes. It is better than `latest`, but it is still a name that someone can move. Production needs more.

## Require a digest in production only

The digest rule matches only namespaces whose label is `environment: production`. The pattern `*@sha256:*` demands that the image string contains `@sha256:`. Development namespaces keep the tag rules and are not forced to use digests.

Save this as `clusterpolicy-require-digest.yaml`:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-digest
spec:
  background: true
  rules:
    - name: pin-by-digest
      match:
        any:
          - resources:
              kinds:
                - Pod
              namespaceSelector:
                matchLabels:
                  environment: production
      validate:
        failureAction: Enforce
        message: "Images in production must be pinned by digest (image@sha256:...)."
        pattern:
          spec:
            containers:
              - image: "*@sha256:*"
```

Apply it:

```sh
kubectl apply -f clusterpolicy-require-digest.yaml
```

Now send three requests to `starfleet-prod`: the tag only, the digest only and the tag together with the digest. The fourth request sends the tag to `starfleet`:

```sh
try_image starfleet-prod ghcr.io/stefanprodan/podinfo:6.15.0
try_image starfleet-prod ghcr.io/stefanprodan/podinfo@sha256:ec73780a8425f59ea49f5bc8cdff0d598805a224fbaa1f86c67a244f250fa9da
try_image starfleet-prod ghcr.io/stefanprodan/podinfo:6.15.0@sha256:ec73780a8425f59ea49f5bc8cdff0d598805a224fbaa1f86c67a244f250fa9da
try_image starfleet ghcr.io/stefanprodan/podinfo:6.15.0
```

Only the first request is rejected. Kyverno blocks the tag in production, accepts both forms with a digest and leaves the development namespace alone:

```text
error: failed to create deployment: admission webhook "validate.kyverno.svc-fail" denied the request: 

resource Deployment/starfleet-prod/image-test was blocked due to the following policies 

require-digest:
  autogen-pin-by-digest: 'validation error: Images in production must be pinned by digest (image@sha256:...). rule autogen-pin-by-digest failed at path /spec/template/spec/containers/0/image/'
deployment.apps/image-test created (server dry run)
deployment.apps/image-test created (server dry run)
deployment.apps/image-test created (server dry run)
```

The `podinfo` digest was copied from the registry. The platform team gets the digest of a trusted image once, for example when the pipeline builds it, and writes the digest in the production manifests. The registry rule, the tag rule and the digest rule now work together, but they all depend on Kyverno. The exam can ask for the same registry rule in Gatekeeper, and the next part writes it.

## Common pitfalls

> [!WARNING]
> - The pattern `*:*` also matches a registry with a port, such as `registry.example.com:5000/app`, even if the image has no tag. Add a stricter pattern if your registry uses a port.
> - `!*:latest` does not catch an image with no tag, which the runtime reads as `latest`. That is why the policy has the separate `require-tag` rule.
> - A digest proves that the content does not change. It does not prove that the content is safe. Admission cannot see inside the image.
> - A policy applies to a namespace through its label. If someone removes the label `environment: production` from the namespace, the digest rule stops applying. Limit who may edit namespace labels with RBAC.
