# Review API Permissions And Pod Admission Separately

Role-based access control and Pod Security Admission run at different points in a request. A service account may be allowed to create a Deployment while that Deployment’s replacement Pods fail admission. Diagnose the permission decision and the workload’s security settings separately.

For access, identify the exact subject, namespace, API group, resource and verb. Inspect every binding that grants the identity rights. Prove an allowed operation and denied controls, including another namespace and sensitive resources. A single successful request cannot establish least privilege.

For Pod Security, inspect the namespace’s enforce, warn and audit settings and their version labels. Existing Pods can remain available after enforcement becomes stricter. A rollout is the point where a ReplicaSet may discover that it cannot create replacements.

Read FailedCreate events and fix the pod template fields named by admission. Keep namespace enforcement in place. A broad role cannot fix an admission rejection, and weakening the namespace does not repair the workload.

Verify the result through the intended identity and through a replacement Pod. Keep original workloads and unrelated grants intact so the exercise demonstrates a bounded repair rather than a rebuilt environment.
