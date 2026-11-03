# Question

Solve this question on: `terminal`

The `starfleet` namespace runs `scout`, `probe`, `shuttle` and a meshed client `caller`, all with Istio sidecars. The namespace `outpost` runs `drifter`, which has no sidecar. Today every pod can send any request to `scout`, with or without mTLS. Close it with Istio resources in `starfleet`. Do not change the workloads and do not touch `outpost`.

1. Require mutual TLS for the whole `starfleet` namespace with a `PeerAuthentication`. A request from `drifter` to `scout` or `probe` must get no HTTP answer. `shuttle` must still reach `probe`.

2. `scout` must answer only `GET` requests from the `shuttle` service account. A `GET` from `caller` (it runs as the `probe` service account) and a `POST` from `shuttle` must both get `403`. Use an `AuthorizationPolicy` with the action `ALLOW`.

3. The path `/env` of `scout` must be closed for every caller, `shuttle` included. All other paths must keep answering `shuttle`. Use an `AuthorizationPolicy` with the action `DENY`.

Do not switch any policy to `PERMISSIVE` or `DISABLE`, and do not delete the policies to make a request work. Do not restrict `probe` with an `AuthorizationPolicy`. The sidecars need a few seconds to receive a new policy, so run a check again if it still shows the old result.

`kubectl` already points at the cluster. Send test requests with `kubectl exec`, for example `kubectl -n starfleet exec deploy/shuttle -c shuttle -- curl ...`.
