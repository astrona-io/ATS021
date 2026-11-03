# Produce Compliance Reports From Policy Engines - Playground

- **ID:** PLAYGROUND
- **Slug:** ats-021-playground-040-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground - clean environment, no task, no grading

A single-node kind cluster (Kubernetes 1.35, `kindest/node:v1.35.8`) with
Kyverno 1.19.1 and Gatekeeper 3.23.1. Two Kyverno ClusterPolicies in `Audit`
mode (`require-limits`, `disallow-latest-tag`) and one Gatekeeper Constraint in
`dryrun` mode (`deployments-need-owner`) already produce results for the
Starfleet workloads. The `probe` Deployment has no resource limits and no
`owner` label, and `legacy-beacon` uses an image with the `latest` tag. API
server audit logging is on, with a short `Metadata`-level policy. The control
plane node container is `astro-ats-021-playground-040-02-control-plane`.
Nothing is submitted.

## Run it

```sh
astrona run -c .
astrona destroy ats-021-playground-040-02
```

`astrona destroy` takes the environment name (`metadata.name` =
`ats-021-playground-040-02`), not the config path. `astrona submit` and
`astrona test` do not apply because there is no grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, preloaded images and the bootstrap script |
| `bootstrap/prepare.sh` | Installs both engines, applies the manifests and turns on audit logging on the node |
| `manifests/starfleet.yaml` | Namespaces, service accounts, workloads and Services |
| `manifests/kyverno-policies.yaml` | The two Audit-mode ClusterPolicies |
| `manifests/gatekeeper-owner-label.yaml` | The `K8sRequiredLabels` ConstraintTemplate |
| `manifests/gatekeeper-owner-constraint.yaml` | The `deployments-need-owner` Constraint (`dryrun`) |
| `docs/overview.md` | What the environment contains and ideas to try |
