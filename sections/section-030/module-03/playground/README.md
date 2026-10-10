# Write ValidatingAdmissionPolicies With CEL - Playground

- **ID:** PLAYGROUND
- **Slug:** ats-021-playground-030-03
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground - clean environment, no task, no grading

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with no
policy engine: the API server evaluates `ValidatingAdmissionPolicy` objects
itself. The `starfleet` namespace is labelled `environment: production` and
runs `scout` at 8 replicas; `outpost` is labelled `environment: sandbox`. A
`replica-limits` ConfigMap in `starfleet` serves as a params resource. The
learner writes the policies and bindings. Nothing is submitted.

## Run it

```sh
astrona run -c .
astrona destroy ats-021-playground-030-03
```

`astrona destroy` takes the environment name (`metadata.name` =
`ats-021-playground-030-03`), not the config path. `astrona submit` and
`astrona test` do not apply because there is no grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, preloaded images and bootstrap manifests |
| `manifests/starfleet.yaml` | Labelled namespaces, service accounts, workloads and Services |
| `manifests/replica-limits.yaml` | ConfigMap used as the params resource |
| `docs/overview.md` | What the environment contains and ideas to try |
