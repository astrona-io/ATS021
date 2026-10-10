# Grant Least-Privilege Access With RBAC — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-021-playground-010-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with the
Starfleet workloads (`scout`, `probe`, `shuttle` in `starfleet`, `drifter` in
`outpost`) on their own service accounts, a `ci-deployer` service account with
no rights, and a `legacy-agent` service account bound to `cluster-admin` on
purpose. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-021-playground-010-01
```

`astrona destroy` takes the environment name (`metadata.name` =
`ats-021-playground-010-01`), not the config path. `astrona submit` and
`astrona test` do not apply — there is no grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded images, starting manifests) |
| `manifests/starfleet.yaml` | Namespaces, service accounts and the Starfleet workloads |
| `manifests/access.yaml` | `ci-deployer`, `legacy-agent` and its over-broad `ClusterRoleBinding` |
| `docs/overview.md` | What the environment contains and ideas to try |
