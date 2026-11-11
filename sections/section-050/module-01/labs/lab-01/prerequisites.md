# Prerequisites

Read the teaching immediately before this lab. You need to inspect Kubernetes objects, save a YAML manifest and apply it with `kubectl`. This lab starts independently; it does not reuse a previous lab or the playground.

Tekton, `deploy-release`, the policy and release ConfigMaps are ready. `pipeline-runner` already has limited deployment access. The Pipeline has no check Task and does not gate deployment.
