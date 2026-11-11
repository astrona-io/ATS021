# Question

Solve this question on: `terminal`

Gatekeeper runs with a working `K8sDisallowedTags` template. The existing `drifter` Pod in `outpost` uses `curlimages/curl:latest`. The platform team wants an inventory of violations before blocking deployments. No constraint has been created.

## Tasks

1. Inspect the template parameters and confirm that `drifter` is Ready with a `latest` image.
2. Create a `K8sDisallowedTags` constraint scoped to Pods in `outpost`, with `tags: ["latest"]` and enforcement action `dryrun`.
3. Find the original `drifter` Pod in the constraint's audit violations. Check the audit timestamp, then prove with server-side dry runs that both latest and pinned images are still accepted in `outpost` and that `starfleet` is unaffected.

## Constraints

- Keep the original Pod running with its original UID and container configuration.
- Preserve Gatekeeper, its webhook and the working template. Do not change the policy to ignore the Pod.

Learner work: about 10 minutes. Cluster startup is separate; allow up to three minutes for the next audit result.
