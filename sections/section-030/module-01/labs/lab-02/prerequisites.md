# Prerequisites

Allow about 20 minutes. You need to write Kubernetes YAML and use
`kubectl apply`, `kubectl get`, `kubectl label` and `kubectl annotate`.
A label is a key and value stored in an object's metadata; an annotation
stores metadata that is not used to select objects.

The environment provides Kubernetes 1.35.8, Kyverno and the Kyverno
command-line interface (CLI) 1.19.1. The `starfleet` and `outpost` namespaces
each contain a `scout` service account. The podinfo 6.15.0 image is preloaded.
No policy or task Pod is created. Offline test fixtures are copied to
`/tmp/kyverno-team-test`; you supply its missing `policy.yaml`.
