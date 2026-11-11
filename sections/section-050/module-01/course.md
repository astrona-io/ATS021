# Gate A Tekton Pipeline On A Compliance Check

A release pipeline builds nothing useful if it deploys whatever it is given. The cluster's admission controllers reject a bad object, but only when the pipeline already tries to deploy it. A check inside the pipeline stops the release earlier, runs under the pipeline's own identity and leaves a record of why the pipeline stopped. Tekton Pipelines is the Kubernetes add-on that runs such a pipeline as Kubernetes objects.

Keep one sentence in mind for this module: **a Task writes the decision to a result, a `when` expression reads it, and the service account limits what the deploy can reach.** You build one pipeline with a check Task, a deploy Task and a `finally` Task, and you run it three times: a release that follows the rules, a release that breaks them, and a release that is compliant but targets a namespace the pipeline may not touch.

The module has four parts. **Run A Compliance Check As A Tekton Task** builds the check and its `pass` or `fail` result. **Gate The Deploy With A when Expression** builds the Pipeline and shows a blocked release. **Run finally On Every Path** runs a compliant release and reads what the `finally` Task reports. **Read A Failed Task And Limit The Service Account** tells a failed Task from a skipped one and checks the rights of the pipeline's service account.

The independent labs practise the compliance gate, reporting every pipeline outcome, and limiting the pipeline service account. Each starts with its supporting resources prepared.

## Learning objectives

After this module you can:

- Write a Tekton Task whose step checks release manifests against policies and writes the outcome to a Task result.
- Stop the deploy Task with a `when` expression that reads the check Task's result.
- Order Tasks with `runAfter` and explain what Tekton does without it.
- Add a `finally` Task that reports the outcome, even when the pipeline fails.
- Run a PipelineRun and read why a Task failed or was skipped with `tkn` and `kubectl`.
- Tell a skipped Task from a failed Task by the TaskRun list and the run status.
- Check the rights of the pipeline's service account with `kubectl auth can-i --as`.

## Before you start

You need `kubectl`, YAML and the idea of a Kubernetes service account. You also need the `tkn` command line tool, version 0.46 or later, on your machine. Tekton gives its own objects (`Task`, `Pipeline`, `PipelineRun`) to the Kubernetes API, so `kubectl` works with them too.

Your playground is a single-node kind cluster running Kubernetes 1.35.8 with Tekton Pipelines 1.17.0. The `pipelines` namespace holds the service account `pipeline-runner`, a prepared Task named `deploy-release`, the ConfigMap `platform-policies` and three release ConfigMaps. The `starfleet` and `outpost` namespaces are empty. The service account may create Deployments in `starfleet` only.

The compliance check runs the Kyverno command line image `ghcr.io/kyverno/kyverno-cli:v1.19.1` as one step. The module treats that image as plumbing and does not teach its options. It is already loaded into the cluster, so a run needs no internet access.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
