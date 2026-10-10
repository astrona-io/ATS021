# Require Mutual TLS And Authorize Callers With Istio — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-021-playground-020-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with
Istio 1.31.1 (`minimal` profile, sidecar mode, installed by `istioctl` from
`bootstrap/prepare.sh`). `starfleet` has sidecar injection and runs `scout`,
`probe` and `shuttle`; `outpost` has no injection and runs `drifter`. No
PeerAuthentication and no AuthorizationPolicy: the mesh starts PERMISSIVE on
purpose. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-021-playground-020-01
```

`astrona destroy` takes the environment name (`metadata.name` =
`ats-021-playground-020-01`), not the config path. `astrona submit` and
`astrona test` do not apply — there is no grading.

`bootstrap/prepare.sh` installs `istioctl` 1.31.1 into `/usr/local/bin` or
`~/.local/bin` when the `istioctl` on the PATH is another version.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime, preloaded images, bootstrap) |
| `bootstrap/prepare.sh` | Installs `istioctl` and Istio, then applies the workloads |
| `manifests/starfleet.yaml` | Namespaces (`starfleet` labelled for injection), service accounts, workloads |
| `docs/overview.md` | What the environment contains and ideas to try |
