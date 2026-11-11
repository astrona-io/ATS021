# Prerequisites

Read the teaching immediately before this lab. You need to inspect Kubernetes objects, save a YAML manifest and apply it with `kubectl`. This lab starts independently; it does not reuse a previous lab or the playground.

Kyverno already enforces the GHCR registry boundary. Development still accepts `latest` and untagged images; production still accepts tags without a digest.
