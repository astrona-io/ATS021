# Prerequisites

Read the teaching immediately before this lab. You need to inspect Kubernetes objects, save a YAML manifest and apply it with `kubectl`. This lab starts independently; it does not reuse a previous lab or the playground.

The Pipeline already checks compliance, gates deployment and reports the outcome. Its `pipeline-runner` identity has a ClusterRoleBinding to `edit`, so it can deploy into unrelated namespaces.
