# Question

Solve this question on: `terminal`

Gatekeeper is installed without any constraints. The namespaces `starfleet` and `starfleet-prod` must admit regular Pod containers only from `ghcr.io/`. The namespace `outpost` must remain outside this rule. This lab exercises admission with server-side dry runs, so test images do not need to be downloaded.

## Tasks

1. Create a `ConstraintTemplate` named `k8sallowedregistries`, producing `K8sAllowedRegistries`. Define a string-array parameter `registries`. Its Rego must check every regular container's image against the supplied prefixes.
2. Create a deny constraint named `ghcr-only` for Pods in `starfleet` and `starfleet-prod`, passing `registries: ["ghcr.io/"]`.
3. Prove that an allowed GHCR image is accepted, an image from Docker Hub is denied, and `ghcr.io.example.com/team/app:v1` is denied in both namespaces. Test a Pod whose first container is allowed and second container is denied. Verify that Docker Hub remains allowed in `outpost`.

## Constraints

- Keep Gatekeeper and its webhook enabled; denials must identify `ghcr-only`.
- Match Pods, not Deployment objects. This exercise covers regular containers; a complete production policy also needs init and ephemeral containers and a policy for image digests.
- Keep policy scope limited to the two named application namespaces.

Learner work: about 15 minutes. Allow additional startup and template reconciliation time.
