# Question

Solve this question on: `terminal`

The `starfleet` namespace runs `scout`, `probe`, `shuttle` and a meshed client `caller`, all with Linkerd proxies. The namespace `outpost` runs `drifter`, which has no proxy. Today every pod can send any request to `scout` and `probe`. Close it with Linkerd policy in `starfleet`. Do not change the workloads and do not touch `outpost`.

1. `scout` must answer only the `shuttle` service account. A request from `shuttle` must get `200`. A request from `drifter` (no proxy) and a request from `caller` (meshed, it runs as the `probe` service account) must both get `403`. Use a `Server` for the `http` port of `scout`, a `MeshTLSAuthentication` and an `AuthorizationPolicy`.

2. `probe` must refuse every client that has no proxy: a request from `drifter` must get `403`. It must keep answering every meshed caller in `starfleet`: `shuttle` and `caller` must get `200`. Do not create a `Server` for `probe`. Set the default inbound policy of the namespace instead. Linkerd proxies read that setting only when a pod starts.

Do not delete a policy resource to make a request work. The proxies need a few seconds to receive a new policy, so run a check again if it still shows the old result.

`kubectl` already points at the cluster. Send test requests with `kubectl exec`, for example `kubectl -n starfleet exec deploy/shuttle -c shuttle -- curl ...`.
