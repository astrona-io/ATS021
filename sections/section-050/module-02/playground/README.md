# Admit Only Trusted Images - Playground

- **ID:** PLAYGROUND
- **Slug:** ats-021-playground-050-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground - clean environment, no task, no grading

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with
Kyverno 1.19.1 and Gatekeeper 3.23.1, the namespaces `starfleet`
(development) and `starfleet-prod` (production), and `scout` in `starfleet`.
`podinfo:6.15.0` is preloaded. The learner writes image
policies. No registry and no signing tools. Nothing is submitted.

## Run it

```sh
astrona run -c .
astrona destroy ats-021-playground-050-02
```

`astrona destroy` takes the environment name (`metadata.name` =
`ats-021-playground-050-02`), not the config path. `astrona submit` and
`astrona test` do not apply because there is no grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, preloaded images and bootstrap script |
| `bootstrap/prepare.sh` | Installs Kyverno and Gatekeeper and applies the starting objects |
| `manifests/starfleet.yaml` | Namespaces, service accounts and `scout` |
| `docs/overview.md` | What the environment contains and ideas to try |
