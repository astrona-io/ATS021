# Question

Solve this question on: `terminal`

The platform team wants a replica limit enforced by the Kubernetes API server itself, with no webhook and no policy engine. The namespace `starfleet` has the label `environment: production`. It runs `scout` with 8 replicas. The namespace `outpost` has the label `environment: sandbox`. The ConfigMap `replica-limits` in `starfleet` holds `maxReplicas: "5"`. Do not change the workloads, the namespace labels or the ConfigMap.

1. Create a `ValidatingAdmissionPolicy` that limits the replicas of Deployments to the number in `replica-limits`. The policy must read the number from the ConfigMap as a parameter and must not write the number into the expression. It must check `kubectl scale` too.

2. Bind the policy to every namespace with the label `environment: production`, so the API server rejects a Deployment that asks for more replicas than the limit. Creating a Deployment with 6 replicas, scaling `scout` to 9 and patching `scout` to 9 must all fail. A Deployment with 5 replicas must be accepted.

3. `scout` already runs 8 replicas. A request that lowers the count (8 to 6, or 8 to 3) must still be accepted, and so must a change that does not touch the count, such as a label. Only a request that raises the count above the limit fails.

4. In every namespace with the label `environment: sandbox`, a Deployment above the limit must be accepted, but the API server must return a warning. Both bindings must find the parameter object in the namespace `starfleet`.

`kubectl` already points at the cluster as the cluster administrator. Use `--dry-run=server` to test a request without storing it.
