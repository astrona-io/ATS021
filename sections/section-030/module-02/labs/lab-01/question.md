# Question

Solve this question on: `terminal`

Gatekeeper 3.23.1 runs in the cluster. The platform team wrote a `ConstraintTemplate` named `k8sdisallowedtags` that must refuse images with a given tag, but nobody can create a constraint from it. The namespace `starfleet` runs `scout`, `probe` and `shuttle`. The namespace `outpost` provides a control outside the policy scope.

1. Find out why `k8sdisallowedtags` does not work and fix the template. Keep its name and its constraint kind `K8sDisallowedTags`. The template must end with `status.created: true`. Its Rego must report a violation for a container whose image ends in `:<tag>` for any tag in the parameter `tags`.

2. Create a Constraint named `no-latest-tag` of kind `K8sDisallowedTags`. It must refuse pods in `starfleet` that use the tag `latest`, and it must pass the tag through the parameter `tags`. A pod with a pinned tag such as `curlimages/curl:8.22.0` must still be accepted.

3. Verify with server-side dry runs that a pinned image is accepted in `starfleet` and that a `latest` image is accepted in `outpost`. Keep Gatekeeper and its webhook enabled.

Learner work: about 15 minutes. Cluster startup and template reconciliation take additional time. Audit investigation is a separate independent lab.

`kubectl` already points at the cluster as the cluster administrator. Gatekeeper takes a few seconds to load a template or a constraint.
