# Question

Solve this question on: `terminal`

The platform team installed Kyverno 1.19.1. The namespace `starfleet` has the label `environment: development`. The namespace `starfleet-prod` has the label `environment: production`. The `ClusterPolicy` `allowed-registries` already exists, but it only records failures, so the cluster still admits any image. Write the image policies below with Kyverno `ClusterPolicy` resources. Every rule must refuse the request, not only record it. Do not remove Kyverno, and do not change the namespace labels.

1. Pods in every namespace that has an `environment` label (any value) must use an image that starts with `ghcr.io/`. The API server must refuse a Deployment that uses an image from another registry, such as `docker.io/library/nginx:1.27.0`, and an image such as `evil.example.com/ghcr.io/stefanprodan/podinfo:6.15.0`. Fix the existing policy `allowed-registries`.

2. In the same namespaces, an image with the tag `latest` and an image with no tag must be refused. A pinned tag, such as `ghcr.io/stefanprodan/podinfo:6.15.0`, must be accepted in `starfleet`.

3. In namespaces labelled `environment: production` only, an image must also be pinned by digest (`@sha256:`). The API server must refuse `ghcr.io/stefanprodan/podinfo:6.15.0` in `starfleet-prod` and accept `ghcr.io/stefanprodan/podinfo@sha256:ec73780a8425f59ea49f5bc8cdff0d598805a224fbaa1f86c67a244f250fa9da` there. The same tag must still be accepted in `starfleet`.

4. Namespaces without an `environment` label, such as `default`, must not be affected.

`kubectl` already points at the cluster as the cluster administrator. Test an image with `kubectl -n <namespace> create deployment image-test --image=<image> --dry-run=server`. Kyverno takes a few seconds to use a changed policy, so run a check again if it still shows the old result. Applying a `kyverno.io/v1` ClusterPolicy prints a deprecation warning. You can ignore it.
