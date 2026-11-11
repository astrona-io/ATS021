# Question

Solve this question on: `terminal`

The application Pods pass the baseline Pod Security Standard but do not meet restricted. The namespace has no Pod Security labels. Prepare the team for restricted without blocking baseline-compliant replacement Pods.

## Tasks

1. Preview an enforce=restricted label change with a server-side dry run and inspect the reported workload violations.

2. Set `enforce: baseline`, `warn: restricted` and `audit: restricted` on `starfleet`, using the `pod-security.kubernetes.io/` labels. Pin all three modes to `v1.35`.

3. Prove that a baseline-only Pod is admitted with a restricted warning, a privileged Pod is rejected, and a restricted-compliant Pod is admitted without that warning. Keep the application available and leave `outpost` unchanged.

Keep the prepared workloads and service accounts unchanged. Only change Pod Security labels on starfleet; leave outpost unchanged.

Learner work: about 15 minutes. Cluster startup and controller reconciliation take additional time.
