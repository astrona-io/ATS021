# Validate, Mutate And Generate With Kyverno — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-021-playground-030-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with
Kyverno 1.19.1, installed from its release manifest by `bootstrap/prepare.sh`
(no Helm). The Starfleet workloads run in `starfleet` and `outpost`; on
purpose, `probe` has no resource limits, `scout` and `shuttle` set only a
memory limit, and `scout` has no `team` label. No ClusterPolicy and no
PolicyException. Kyverno's PolicyException support is off, as in a default
installation (`--enablePolicyException=false`). Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-021-playground-030-01
```

`astrona destroy` takes the environment name (`metadata.name` =
`ats-021-playground-030-01`), not the config path. `astrona submit` and
`astrona test` do not apply — there is no grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded images, bootstrap) |
| `bootstrap/prepare.sh` | Installs Kyverno, waits for its webhooks, then applies the workloads |
| `manifests/starfleet.yaml` | Namespaces, service accounts and workloads, with the deliberate gaps |
| `docs/overview.md` | What the environment contains and ideas to try |
