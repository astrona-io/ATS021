# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. The output below comes from the module that teaches this task. Long Kyverno messages are shortened where the text says so.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-050/module-02/labs/lab-01
```

Paste this helper. It asks the API server, without storing anything, whether a Deployment with the given image is accepted in a namespace:

```sh
try_image() {
  kubectl -n "$1" create deployment image-test --image="$2" --dry-run=server
}
```

`astrona submit` right after the start shows that one check passes: the namespaces are unchanged and `default` is not affected. The other three fail.

## Step 1: Enforce the registry rule

The policy `allowed-registries` has `failureAction: Audit`, which records a failure and still admits the request. Change it to `Enforce`. The pattern `ghcr.io/*` matches the start of the image string, so it also refuses `evil.example.com/ghcr.io/...`. Save the corrected policy as `clusterpolicy-allowed-registries.yaml`:

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

Kyverno prints a deprecation warning for the `kyverno.io/v1` kind. The old kind still works. Wait about ten seconds. Send an image from `docker.io` to `starfleet`:

```sh
try_image starfleet nginx:latest
```

The API server rejects it. You should see something like this. The webhook name `validate.kyverno.svc-fail` shows that Kyverno answered:

```text
error: failed to create deployment: admission webhook "validate.kyverno.svc-fail" denied the request: 

resource Deployment/starfleet/image-test was blocked due to the following policies 

allowed-registries:
  autogen-only-ghcr: 'validation error: Images must come from ghcr.io. rule autogen-only-ghcr failed at path /spec/template/spec/containers/0/image/'
```

The rule name has the prefix `autogen-`, because Kyverno generates the Deployment rule from the Pod rule. Send an image from `ghcr.io`, and send the `docker.io` image to `default`:

```sh
try_image starfleet ghcr.io/stefanprodan/podinfo:6.15.0
try_image default nginx:latest
```

```text
deployment.apps/image-test created (server dry run)
deployment.apps/image-test created (server dry run)
```

Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-050/module-02/labs/lab-01 --keep
```

The check `registry-enforced` now passes. Do not leave the policy in `Audit` mode, and do not delete it.

## Step 2: Refuse latest and untagged images

One policy can hold two rules. The rule `require-tag` uses the pattern `*:*`, so the image string must contain a colon. The rule `disallow-latest` uses the pattern `!*:latest`, where the `!` negates the match. A digest contains a colon, so a digest reference passes the first rule. Save this as `clusterpolicy-image-tags.yaml`:

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

Wait about ten seconds, then send a `latest` tag, a reference with no tag and a pinned tag. All three images come from `ghcr.io`:

```sh
try_image starfleet ghcr.io/stefanprodan/podinfo:latest
try_image starfleet ghcr.io/stefanprodan/podinfo
try_image starfleet ghcr.io/stefanprodan/podinfo:6.15.0
```

The first two requests fail. The first fails the rule `autogen-disallow-latest` and the second fails the rule `autogen-require-tag`. The third request prints `deployment.apps/image-test created (server dry run)`. Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-050/module-02/labs/lab-01 --keep
```

The check `mutable-tags-rejected` now passes.

## Step 3: Require a digest in production only

The digest rule selects namespaces with `matchLabels` on `environment: production`, so `starfleet` is not affected. The pattern `*@sha256:*` requires `@sha256:` in the image string. Save this as `clusterpolicy-require-digest.yaml`:

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

Wait about ten seconds. Send three requests to `starfleet-prod` and one to `starfleet`:

```sh
try_image starfleet-prod ghcr.io/stefanprodan/podinfo:6.15.0
try_image starfleet-prod ghcr.io/stefanprodan/podinfo@sha256:ec73780a8425f59ea49f5bc8cdff0d598805a224fbaa1f86c67a244f250fa9da
try_image starfleet-prod ghcr.io/stefanprodan/podinfo:6.15.0@sha256:ec73780a8425f59ea49f5bc8cdff0d598805a224fbaa1f86c67a244f250fa9da
try_image starfleet ghcr.io/stefanprodan/podinfo:6.15.0
```

Only the first request is rejected, with the rule `autogen-pin-by-digest`. The other three print `deployment.apps/image-test created (server dry run)`. Check that all three policies are ready:

```sh
kubectl get clusterpolicy
```

You should see `READY` as `True` for `allowed-registries`, `image-tags` and `require-digest`. Right after an apply, `READY` can be empty for a few seconds. Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-050/module-02/labs/lab-01
```

All four checks pass. Do not switch the digest rule to every namespace and do not remove the label from `starfleet-prod`. The grader rejects both. Clean up:

```sh
astrona destroy ats-021-lab-050-02
```
