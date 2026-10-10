# Require Mutual TLS And Authorize Callers With Linkerd — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-021-playground-020-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with
Linkerd edge-26.10.1, its CRDs, the Gateway API CRDs v1.4.0 it uses, and the
`viz` extension, installed by the `linkerd` CLI from `bootstrap/prepare.sh`.
`starfleet` has proxy injection and runs `scout`, `probe` and `shuttle`;
`outpost` has no injection and runs `drifter`. The default inbound policy is
`all-unauthenticated` and there is no Server or AuthorizationPolicy, on purpose.
No Istio. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-021-playground-020-02
```

`astrona destroy` takes the environment name (`metadata.name` =
`ats-021-playground-020-02`), not the config path. `astrona submit` and
`astrona test` do not apply — there is no grading.

`bootstrap/prepare.sh` installs the `linkerd` CLI edge-26.10.1 into
`/usr/local/bin` or `~/.local/bin` when the `linkerd` on the PATH is another
version. Starting takes about two minutes.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded images, bootstrap) |
| `bootstrap/prepare.sh` | Installs the CLI, Gateway API CRDs, Linkerd and `viz`, then applies the workloads |
| `manifests/starfleet.yaml` | Namespaces (`starfleet` annotated for injection), service accounts, workloads |
| `docs/overview.md` | What the environment contains and ideas to try |
