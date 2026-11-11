# Prerequisites

Read the teaching immediately before this lab. You need to inspect Kubernetes objects, save a YAML manifest and apply it with `kubectl`. This lab starts independently; it does not reuse a previous lab or the playground.

The `scale-operator` service account has no resource permissions. It must change only the replica count of `starfleet/scout`, without permission to change the Deployment template.
