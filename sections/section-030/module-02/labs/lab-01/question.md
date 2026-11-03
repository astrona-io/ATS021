# Question

Solve this question on: `terminal`

Gatekeeper 3.23.1 runs in the cluster. The platform team wrote a `ConstraintTemplate` named `k8sdisallowedtags` that must refuse images with a given tag, but nobody can create a constraint from it. The namespace `starfleet` runs `scout`, `probe` and `shuttle`. The namespace `outpost` runs `drifter`, which uses the `latest` tag today.

1. Find out why `k8sdisallowedtags` does not work and fix the template. Keep its name and its constraint kind `K8sDisallowedTags`. The template must end with `status.created: true`. Its Rego must report a violation for a container whose image ends in `:<tag>` for any tag in the parameter `tags`.

2. Create a Constraint named `no-latest-tag` of kind `K8sDisallowedTags`. It must refuse pods in `starfleet` that use the tag `latest`, and it must pass the tag through the parameter `tags`. A pod with a pinned tag such as `curlimages/curl:8.22.0` must still be accepted.

3. `drifter` in `outpost` must keep running, and new pods in `outpost` must still be accepted. Create a second Constraint of the same kind for `outpost`, with the same parameter, that only records violations. After the next audit run, the `drifter` pod must appear in the audit results of that constraint.

`kubectl` already points at the cluster as the cluster administrator. Gatekeeper takes a few seconds to load a template or a constraint, and the audit controller runs about once a minute.
