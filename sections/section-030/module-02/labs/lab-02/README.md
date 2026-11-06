---
estimated_duration: 25m
---

# Lab: Satisfy A Gatekeeper Constraint With A Helm Chart

Graded lab for the Gatekeeper module. The cluster starts with Gatekeeper 3.23.1, Helm 4.3.0 on the terminal, the Starfleet workloads, and the `probe` chart copied to `~/resources/probe` and installed as release `probe` (revision 1) in `starfleet`. The chart runs one replica and puts the `team` label on the Deployment only, not on the pod template. The learner writes one ConstraintTemplate with two violation rules (Pods need the `team` label, Deployments need at least two replicas), one `deny` Constraint for `starfleet`, then repairs the chart, raises its version to `0.2.0` and upgrades the release until it runs. The task is in `question.md`; the walkthrough is in `solution.md`.

Helm basics (chart layout, values, `helm upgrade`, `helm history`) are taught in the ATS018 course; this lab only uses them. Helm is installed the way the ATS018 labs do it: `bootstrap/00-install-helm.sh` puts the pinned binary in `~/.astrona/bin`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-030/module-02/labs/lab-02
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-030/module-02/labs/lab-02
astrona destroy ats-021-lab-030-02-02
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Layout

| Path | Purpose |
| --- | --- |
| `bootstrap/00-install-helm.sh` | Installs Helm 4.3.0 in `~/.astrona/bin` with a checksum check |
| `bootstrap/01-seed-cluster.sh` | Installs Gatekeeper 3.23.1, the workloads, copies the chart to `~/resources/probe` and installs revision 1 |
| `manifests/lab-start.yaml` | Namespaces, service accounts, `scout`, `shuttle` and `drifter` (no `probe` Deployment; the chart installs it) |
| `resources/probe/` | The faulty chart (version `0.1.0`, one replica, label on the Deployment only) |
| `solution/` | Reference template, constraint, repaired chart (`0.2.0`) and `apply.sh` |
| `testing/wait-for-constraint.sh` | Waits until the constraint refuses an unlabelled pod, for `astrona test` |
| `validation/` | One script per check |

## Checks

The admission checks use `--dry-run=server`, so the Gatekeeper webhook runs and nothing is stored.

| Script | What it proves |
| --- | --- |
| `validate-template-created.sh` | `k8sstarfleetworkloadrules` has `status.created: true`, its CustomResourceDefinition exists and the kind is `K8sStarfleetWorkloadRules` |
| `validate-pod-rule.sh` | A pod without `team` is refused in `starfleet`; a pod with `team` is accepted there; a pod without `team` is accepted in `outpost` |
| `validate-deployment-rule.sh` | A labelled one-replica Deployment is refused in `starfleet`; two replicas are accepted there; one replica is accepted in `outpost` |
| `validate-release-repaired.sh` | `~/resources/probe/Chart.yaml` has version `0.2.0`, the chart lints and renders, the release `probe` is `deployed` with chart `probe-0.2.0`, and `helm get manifest` equals `helm template` of the saved chart |
| `validate-release-pods-ready.sh` | The Helm-managed `probe` Deployment has at least two replicas, all ready, the `team` label on the pod template and on every pod |

The release starts as revision 1 so that the learner meets the refusal through `helm upgrade`, not through a failed first install. A `warn` or `dryrun` constraint fails the two admission checks. A fix made with `--set` fails `release-repaired`, because the saved chart then renders differently from the release.

Built without booting on 2026-11-06. Static checks only (`astrona validate`, `bash -n`, YAML parsing, `helm lint`, `helm template`); live behaviour has not been run.
