# Overview: Gate A Tekton Pipeline On A Compliance Check (Playground)

This playground starts a fresh Kubernetes cluster for building a Tekton pipeline that checks a release before it deploys. There is no grading. You write the check Task and the Pipeline yourself.

## What's in the box

The single-node kind cluster runs Kubernetes 1.35.8 with Tekton Pipelines 1.17.0. You need the `tkn` command line tool (version 0.46 or later) on your machine.

| Namespace | Contents |
| --- | --- |
| `tekton-pipelines` | The Tekton controller and webhook |
| `pipelines` | The service account `pipeline-runner`, the `deploy-release` Task, the ConfigMap `platform-policies` and three release ConfigMaps |
| `starfleet` | Empty. The pipeline deploys `scout` here |
| `outpost` | Empty. `pipeline-runner` has no rights here |

The three release ConfigMaps each hold one file, `deployment.yaml`, with a `scout` Deployment:

- `release-compliant` sets CPU and memory limits and uses the image `ghcr.io/stefanprodan/podinfo:6.15.0`.
- `release-noncompliant` has no limits and uses the image `ghcr.io/stefanprodan/podinfo:latest`.
- `release-outpost` is compliant, but targets the `outpost` namespace.

The ConfigMap `platform-policies` holds the file `policies.yaml` with two Kyverno rules for Deployments: every container sets CPU and memory limits, and no image uses the `latest` tag. The service account `pipeline-runner` may `get`, `list`, `create` and `patch` Deployments in `starfleet` only.

The check step uses the image `ghcr.io/kyverno/kyverno-cli:v1.19.1`. It is preloaded into the cluster, so a run needs no internet access.

## Practice tasks

- Write a `check-release` Task that runs the Kyverno CLI image against a release and writes `pass` or `fail` to a Task result.
- Write a `release-gate` Pipeline with a check Task, a deploy Task with a `when` expression, and a `finally` Task.
- Run the Pipeline with each release and read the result with `tkn pipelinerun describe`.
- Run the Pipeline with the `release-outpost` release and read why the deploy Task fails.
- Ask `kubectl auth can-i` what `pipeline-runner` may do, and try one more verb that you expect to be denied.
