# Record API Activity With Audit Logging - Playground

- **ID:** PLAYGROUND
- **Slug:** ats-021-playground-040-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground - clean environment, no task, no grading

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with API
server audit logging switched off. The Starfleet workloads run in `starfleet`
and `outpost`. A `deck-cleaner` CronJob in `outpost` (service account
`deck-cleaner`) calls the API server with curl every two minutes: it reads the
Secret `scout-db-credentials` and deletes and recreates the `probe` Deployment
in `starfleet`. The learner turns on audit logging on the control plane node
container (`astro-ats-021-playground-040-01-control-plane`) and finds that
activity in the log. Nothing is submitted.

## Run it

```sh
astrona run -c .
astrona destroy ats-021-playground-040-01
```

`astrona destroy` takes the environment name (`metadata.name` =
`ats-021-playground-040-01`), not the config path. `astrona submit` and
`astrona test` do not apply because there is no grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, preloaded images and bootstrap manifests |
| `manifests/starfleet.yaml` | Namespaces, service accounts, workloads and Services |
| `manifests/deck-cleaner.yaml` | Secret, Role, RoleBinding, ConfigMap and CronJob that create the audit activity |
| `docs/overview.md` | What the environment contains and ideas to try |
