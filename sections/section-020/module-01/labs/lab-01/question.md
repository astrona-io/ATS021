# Question

Solve this question on: `terminal`

`starfleet` has Istio sidecars but accepts plaintext traffic. `drifter` in `outpost` has no sidecar. No authentication or authorization policy exists.

## Tasks

1. Confirm that `shuttle` and plaintext `drifter` can reach `scout` before the change.

2. Require STRICT mutual TLS across `starfleet` with a namespace-wide PeerAuthentication.

3. Prove that `drifter` gets no HTTP response from either `scout` or `probe`, while meshed `shuttle` still reaches both Services.

Keep every workload and namespace unchanged. Do not add an AuthorizationPolicy; this task proves transport authentication.

Learner work: about 15 minutes. Cluster startup and controller reconciliation take additional time.
