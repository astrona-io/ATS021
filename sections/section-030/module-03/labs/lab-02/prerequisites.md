# Prerequisites

Read the teaching immediately before this lab. You need to inspect Kubernetes objects, save a YAML manifest and apply it with `kubectl`. This lab starts independently; it does not reuse a previous lab or the playground.

The enforcing `workload-check` policy in `starfleet` rejects compliant Deployments. One expression reads `replica` instead of `replicas`; another reads `labels.team` without checking whether the key exists. The same binding must continue enforcing both rules.
