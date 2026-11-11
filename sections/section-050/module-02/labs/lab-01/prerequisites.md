# Prerequisites

Read the teaching immediately before this lab. You need to inspect Kubernetes objects, save a YAML manifest and apply it with `kubectl`. This lab starts independently; it does not reuse a previous lab or the playground.

Kyverno runs with an Audit-mode `allowed-registries` policy. `starfleet` has `environment: development`; `starfleet-prod` has `environment: production`. Other namespaces have no environment label.
