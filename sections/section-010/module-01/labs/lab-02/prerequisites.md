# Prerequisites

Read the teaching immediately before this lab. You need to inspect Kubernetes objects, save a YAML manifest and apply it with `kubectl`. This lab starts independently; it does not reuse a previous lab or the playground.

The `legacy-agent` service account in `starfleet` is bound to `cluster-admin`. It needs only to read Pods in its own namespace.
