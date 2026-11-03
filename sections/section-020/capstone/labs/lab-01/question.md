# Question

Solve this question on: `terminal`

This is the Section 020 capstone: one integrated service-to-service security task, no step-by-step guidance.

The `starfleet` namespace runs `scout`, `probe`, `shuttle`, `caller` and `beacon` on Istio. `caller` runs as the `probe` service account. `beacon` runs as the `shuttle` service account. The namespace `outpost` runs two outside clients: `drifter` has a sidecar, `drifter-plain` has none. Today the mesh accepts plain text and every pod can call every workload. Secure `starfleet` with Istio resources, without changing `outpost`.

1. `starfleet` must accept only mTLS traffic. A request from `drifter-plain` to `scout` or `probe` must get no HTTP answer.

2. `scout` must answer only `GET` requests from the `shuttle` service account. A `POST` from `shuttle`, and a `GET` from `caller` or from `drifter`, must get `403`.

3. `probe` must be reachable only from inside `starfleet`. `shuttle` and `caller` must get `200`. `drifter` has a sidecar, so mTLS alone does not stop it: it must get `403`.

4. `beacon` must keep working under the new rules. Its pods must have a sidecar, and a `GET` from `beacon` to `scout` must return `200`.

Do not use `PERMISSIVE` or `DISABLE`, and do not delete a policy to make a request work. The sidecars need a few seconds to receive a new policy, so run a check again if it still shows the old result.

`kubectl` already points at the cluster. Send test requests with `kubectl exec`, for example `kubectl -n starfleet exec deploy/shuttle -c shuttle -- curl ...`.
