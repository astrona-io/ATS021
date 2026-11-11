# Question

Solve this question on: `terminal`

Three application namespaces already exist: `navigation`, `telemetry` and `research`. Each contains one running Pod named `scout`. Exactly one Pod violates the baseline Pod Security Standard. Its namespace varies between lab starts.

## Tasks

1. Configure all three application namespaces so that Pod Security Admission warns about baseline violations without rejecting the workload. Use the Kubernetes documentation to find the required namespace configuration.

2. Identify which namespace contains the running Pod that violates baseline. Inspect the policy warning and the Pod specification to confirm the cause.

3. Add `security-review=required` only to that namespace. Leave the label absent from the other two.

Keep the three original Pods running and leave their specifications unchanged. Do not delete or recreate Pods or namespaces, add more Pods, or enable enforcement. Inspect existing workloads with server-side dry runs. Leave system namespaces unchanged.

Learner work: about 15 minutes. Cluster startup and controller reconciliation take additional time.
