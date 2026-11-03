# Gate A Tekton Pipeline On A Compliance Check - Playground

- **ID:** PLAYGROUND
- **Slug:** ats-021-playground-050-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground - clean environment, no task, no grading

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with
Tekton Pipelines 1.17.0. The `pipelines` namespace holds the service account
`pipeline-runner` (Deployments in `starfleet` only), the prepared
`deploy-release` Task, the platform policy file and two `scout` releases in
ConfigMaps. The check step runs the Kyverno CLI image
(`ghcr.io/kyverno/kyverno-cli:v1.19.1`) as plumbing. The learner writes the
check Task and the Pipeline. Nothing is submitted.

## Run it

```sh
astrona run -c .
astrona destroy ats-021-playground-050-01
```

`astrona destroy` takes the environment name (`metadata.name` =
`ats-021-playground-050-01`), not the config path. `astrona submit` and
`astrona test` do not apply because there is no grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, preloaded images and bootstrap script |
| `bootstrap/prepare.sh` | Installs Tekton Pipelines and applies the pipeline setup |
| `manifests/pipeline-setup.yaml` | Namespaces, service account, Role, deploy Task, policy file and releases |
| `docs/overview.md` | What the environment contains and ideas to try |
