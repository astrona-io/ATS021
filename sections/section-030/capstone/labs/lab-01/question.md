# Question

Solve this question on: `terminal`

This is the Section 030 capstone: one integrated policy task, no step-by-step guidance.

The platform team runs Kyverno 1.19.1 and Gatekeeper 3.23.1 in the cluster. The Gatekeeper `ConstraintTemplate` `k8sdisallowedtags` already works and creates the constraint kind `K8sDisallowedTags` with the parameter `tags`. The namespace `starfleet` has the label `environment: production`. It runs `scout` (8 replicas), `probe`, `shuttle` and `beacon`. The pods of `probe` have no resource limits because it is a legacy workload with the label `app: probe`. `beacon` uses the image `curlimages/curl:latest`. The namespace `outpost` has the label `environment: sandbox` and runs `drifter`. No policy exists yet. Enforce three rules with three different mechanisms, and bring the existing workloads in line.

1. Use a Kyverno `ClusterPolicy` in `Enforce` mode. Every container in a pod in `starfleet` must set `resources.limits.cpu` and `resources.limits.memory`. The API server must also refuse a Deployment whose pod template does not. The rule must not apply to `outpost`. Pods of `probe` must keep working, so pods with the label `app: probe` may run without limits. Every other pod without limits must be refused. Do not exclude the whole namespace.

2. Use a Gatekeeper Constraint of kind `K8sDisallowedTags` that refuses the tag `latest` for pods in `starfleet`. A pod with a pinned tag, such as `curlimages/curl:8.22.0`, must still be accepted.

3. `beacon` must stop using the `latest` tag. Change its image to `curlimages/curl:8.22.0`. After the next Gatekeeper audit run, the constraint from rule 2 must report no violation.

4. Use a `ValidatingAdmissionPolicy` and a `ValidatingAdmissionPolicyBinding` so that the API server refuses a Deployment with more than 5 replicas in every namespace with the label `environment: production`. The rule must also check `kubectl scale`. A Deployment with 5 replicas must be accepted, and `outpost` must not be affected.

5. `scout` must run at most 5 replicas.

Do not delete the Kyverno or Gatekeeper installation, the template or a workload. Do not use `Audit` or `dryrun` modes for the rules above. `kubectl` already points at the cluster as the cluster administrator. Both engines need a few seconds to load a new rule, and the Gatekeeper audit runs about once a minute. Applying a `kyverno.io/v1` ClusterPolicy prints a deprecation warning. You can ignore it.
