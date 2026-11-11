# Question

Solve this question on: `terminal`

STRICT mutual TLS already protects `starfleet`. Meshed clients can still call any `scout` endpoint. `caller` uses the `probe` service account; `shuttle` has its own identity.

## Tasks

1. Inspect the existing PeerAuthentication and keep its STRICT setting.

2. Use an ALLOW AuthorizationPolicy so only the `shuttle` service account can send GET requests to `scout`. Other callers and POST requests must receive 403.

3. Use a DENY AuthorizationPolicy to reject `/env` even for `shuttle`. Keep other paths available to `shuttle` and leave `probe` without an AuthorizationPolicy.

Keep the prepared workloads, service accounts and namespace labels unchanged.

Learner work: about 15 minutes. Cluster startup and controller reconciliation take additional time.
