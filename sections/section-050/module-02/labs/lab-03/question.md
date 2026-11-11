# Question

Solve this question on: `terminal`

Kyverno already enforces the GHCR registry boundary. Development still accepts `latest` and untagged images; production still accepts tags without a digest.

## Tasks

1. Reject `latest` and images without an explicit tag or digest in every namespace with an `environment` label.

2. Require an `@sha256:` digest in production namespaces while preserving explicit tags in development.

3. Test latest, untagged, versioned and digest references in both environments. Keep namespaces without an `environment` label unaffected.

Keep the prepared workloads, service accounts and namespace labels unchanged.

Learner work: about 15 minutes. Cluster startup and controller reconciliation take additional time.
