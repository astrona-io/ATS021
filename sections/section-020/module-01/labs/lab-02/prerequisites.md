# Prerequisites

Read the teaching immediately before this lab. You need to inspect Kubernetes objects, save a YAML manifest and apply it with `kubectl`. This lab starts independently; it does not reuse a previous lab or the playground.

STRICT mutual TLS already protects `starfleet`. Meshed clients can still call any `scout` endpoint. `caller` uses the `probe` service account; `shuttle` has its own identity.
