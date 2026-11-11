# Prerequisites

Read the teaching immediately before this lab. You need to inspect Kubernetes objects, save a YAML manifest and apply it with `kubectl`. This lab starts independently; it does not reuse a previous lab or the playground.

`starfleet` has Istio sidecars but accepts plaintext traffic. `drifter` in `outpost` has no sidecar. No authentication or authorization policy exists.
