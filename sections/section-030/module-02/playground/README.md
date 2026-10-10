# Enforce Constraints With Gatekeeper And Rego - Playground

- **ID:** PLAYGROUND
- **Slug:** ats-021-playground-030-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground - clean environment, no task, no grading

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with
Gatekeeper 3.23.1, the `starfleet` and `outpost` namespaces, the Starfleet
workloads, and one broken `ConstraintTemplate` for status inspection. The
learner writes working templates and constraints. Nothing is submitted.

## Run it

```sh
astrona run -c .
astrona destroy ats-021-playground-030-02
```

`astrona destroy` takes the environment name (`metadata.name` =
`ats-021-playground-030-02`), not the config path. `astrona submit` and
`astrona test` do not apply because there is no grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, preloaded images and bootstrap script |
| `bootstrap/prepare.sh` | Installs Gatekeeper and applies the starting objects |
| `manifests/starfleet.yaml` | Namespaces, service accounts, workloads and Services |
| `manifests/broken-template.yaml` | Broken `ConstraintTemplate` for status inspection |
| `docs/overview.md` | What the environment contains and ideas to try |
