# Prerequisites

Read the teaching immediately before this lab. You need to inspect Kubernetes objects, save a YAML manifest and apply it with `kubectl`. This lab starts independently; it does not reuse a previous lab or the playground.

Kyverno is ready without policies. New Pods in `starfleet` need a default `team` label, while an explicitly supplied label must survive admission.
