# Question

Solve this question on: `terminal`

The release pipeline of the `starfleet` team runs in the namespace `pipelines` on Tekton Pipelines 1.17.0. The Pipeline `release-gate` is not finished: it deploys every release, even a release that breaks the platform rules, and nothing reports the outcome. The service account `pipeline-runner` also has more rights than the deploy step needs. A new run starts the Pipeline with the service account `pipeline-runner` and two workspaces. The workspace `release` holds the file `deployment.yaml` with one Deployment. The workspace `policies` holds the file `policies.yaml` with the platform rules.

The namespace `pipelines` already has the Tasks `deploy-release` and `report-outcome`. It also has the ConfigMap `platform-policies` and three releases you can try (`release-compliant`, `release-noncompliant` and `release-outpost`). Do not change these objects.

1. Create the Task `check-release` in the namespace `pipelines`. It has the workspaces `release` and `policies` and the result `outcome`. One step runs the image `ghcr.io/kyverno/kyverno-cli:v1.19.1` with the arguments `apply <policies path>/policies.yaml --resource <release path>/deployment.yaml`. A second step writes the word `pass` to the result `outcome` when the first step exited with code `0`, and the word `fail` otherwise. Write the word without a newline. The Task itself must succeed in both cases.

2. Change the Pipeline `release-gate`. The Pipeline Task `deploy` must run only when the result `outcome` of the Pipeline Task `check` is `pass`. Tekton must skip it in every other case. Keep the names `check` and `deploy` and keep the two workspaces.

3. Add a `finally` Task to `release-gate` that uses the Task `report-outcome`. Name the Pipeline Task `report`. It receives the status of all Tasks in the parameter `pipeline-status` and the status of `check` in the parameter `check-status`. It must run after a deployed release, a blocked release and a release whose deploy fails.

4. Give the service account `pipeline-runner` only the rights the deploy step needs. It must be able to `get`, `list`, `create` and `patch` Deployments in the namespace `starfleet`, and nothing else in any namespace. In particular, it must not deploy into `outpost`, delete Deployments or read Secrets. Remove the grant that is too broad. Do not delete the service account.

`kubectl` already points at the cluster as the cluster administrator. You can test your work by starting the Pipeline with the three prepared releases. A run takes about 30 seconds. The grader uses its own policy file and releases, so do not tune the Pipeline to the prepared ones.
