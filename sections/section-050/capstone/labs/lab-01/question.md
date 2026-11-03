# Question

Solve this question on: `terminal`

This is the Section 050 capstone: one integrated task, no step-by-step guidance.

The `starfleet` team releases through the Tekton Pipeline `release-gate` in the namespace `pipelines`. The Pipeline only deploys: it has no check and no report. The service account `pipeline-runner` has the built-in `edit` role in `starfleet` and `outpost`. The production namespace `starfleet-prod` (label `environment: production`) admits any image, because the Kyverno policy `trusted-images` only records failures. A new run starts the Pipeline with the service account `pipeline-runner` and two workspaces. The workspace `release` holds the file `deployment.yaml` with one Deployment. The workspace `policies` holds the file `policies.yaml` with the platform rules.

The namespace `pipelines` already has the Tasks `deploy-release` and `report-outcome`, the ConfigMap `platform-policies` and three releases you can try (`release-compliant`, `release-noncompliant` and `release-outpost`). Do not change these objects. Do not change the namespace labels, and do not remove Kyverno or Tekton.

1. Create the Task `check-release` in the namespace `pipelines`. It has the workspaces `release` and `policies` and the result `outcome`. One step runs the image `ghcr.io/kyverno/kyverno-cli:v1.19.1` with the arguments `apply <policies path>/policies.yaml --resource <release path>/deployment.yaml`. A second step writes the word `pass` to the result `outcome` when the first step exited with code `0`, and the word `fail` otherwise. Write the word without a newline. The Task itself must succeed in both cases.

2. Change the Pipeline `release-gate`. Add the workspace `policies` and a Pipeline Task `check` that uses `check-release`. The Pipeline Task `deploy` must run only when the result `outcome` of `check` is `pass`. Tekton must skip it in every other case. Keep the workspace `release`.

3. Add a `finally` Task named `report` that uses the Task `report-outcome`. It receives the status of all Tasks in the parameter `pipeline-status` and the status of `check` in the parameter `check-status`. It must run after a deployed release, a blocked release and a release whose deploy fails.

4. Give `pipeline-runner` only the rights the deploy step needs: `get`, `list`, `create` and `patch` on Deployments in the namespace `starfleet`, and nothing else in any namespace. It must not deploy into `outpost`, delete Deployments or read Secrets. Remove the grants that are too broad. Do not delete the service account.

5. Fix the image policy `trusted-images`. In namespaces labelled `environment: production`, the API server must refuse a Deployment whose image is not from `ghcr.io` (also `evil.example.com/ghcr.io/stefanprodan/podinfo@sha256:...`) and a Deployment whose image is not pinned by digest (`@sha256:`). It must accept `ghcr.io/stefanprodan/podinfo@sha256:ec73780a8425f59ea49f5bc8cdff0d598805a224fbaa1f86c67a244f250fa9da` in `starfleet-prod`. Namespaces without that label, such as `starfleet` (development) and `default`, must not be affected: `ghcr.io/stefanprodan/podinfo:6.15.0` stays valid in `starfleet` and `nginx:latest` stays valid in `default`.

`kubectl` already points at the cluster as the cluster administrator. A pipeline run takes about 30 seconds. Test an image with `kubectl -n <namespace> create deployment image-test --image=<image> --dry-run=server`. Kyverno takes a few seconds to use a changed policy. The grader uses its own policy file and releases, so do not tune the Pipeline to the prepared ones.
