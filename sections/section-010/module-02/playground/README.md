# Restrict Pods With Pod Security Admission — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-021-playground-010-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`). The
Starfleet workloads run in `starfleet` with no Pod Security labels and no
`securityContext`, next to a privileged `privileged-debug` Deployment with a
`hostPath` mount (on purpose). `outpost` enforces `baseline`. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-021-playground-010-02
```

`astrona destroy` takes the environment name (`metadata.name` =
`ats-021-playground-010-02`), not the config path. `astrona submit` and
`astrona test` do not apply — there is no grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded images, starting manifests) |
| `manifests/starfleet.yaml` | Namespaces (`outpost` labelled `enforce: baseline`), service accounts, workloads |
| `manifests/privileged-debug.yaml` | The privileged Deployment that `baseline` and `restricted` must reject |
| `docs/overview.md` | What the environment contains and ideas to try |
