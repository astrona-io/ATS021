# Question

Solve this question on: `terminal`

This is the Section 010 capstone: one integrated access control task, no step-by-step guidance.

A new team namespace called `orbit` is being onboarded. It runs a Deployment `beacon` and a Service `beacon`. The team's deploy pipeline uses the service account `ci-deployer` in `orbit`. Make the namespace safe.

1. `ci-deployer` must be able to read (`get`, `list`, `watch`), create, `update`, `patch` and `delete` Deployments and Services in `orbit`. It must not be able to read Secrets, create pods, or do anything in another namespace or cluster-wide. Use a Role and a RoleBinding.

2. `ci-deployer` has an inherited grant of `cluster-admin`. Remove it, but keep the service account.

3. Enforce the `restricted` Pod Security Standards level on `orbit` with the namespace label `pod-security.kubernetes.io/enforce`. A privileged pod must be rejected.

4. The `beacon` pods do not meet `restricted`. Change the `beacon` Deployment so its pods are admitted and available, and the Service `beacon` has a ready endpoint. Do not delete or scale down the Deployment.

`kubectl` already points at the cluster as the cluster administrator. You can check any identity with `--as`.
