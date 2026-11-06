# Solution

On `terminal`, connect the release inventory and scan result to deployment,
retain the evidence, and enforce signatures in production. A software bill of
materials (SBOM) records the detected inventory; the scan report records
known vulnerabilities at scan time.

| Goal | Tekton field or file |
| --- | --- |
| Keep the inventory | `evidence` workspace, one directory per run |
| Export the decision | `outcome` result |
| Select deployment | `when` on `$(tasks.check.results.outcome)` |
| Explain the decision | `scan.json`, `database.json` and finally logs |
| Require trusted signatures | `signed-production` ImageValidatingPolicy |

Keep this command running in a second host terminal. It grades the lab every few seconds and records nothing:

```sh
astrona submit --watch --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-050/capstone/labs/lab-02
```

Use `--watch` until the end, because a plain `astrona submit` finishes the attempt and deletes the lab. Run the plain command once, in the last step.

## Step 1: Inspect the prepared objects

```sh
kubectl -n pipelines get pipeline release-scan-gate -o yaml
kubectl -n pipelines get task deploy-scanned-release -o yaml
kubectl -n pipelines get pvc release-scan-evidence
kubectl -n pipelines get configmap scan-release-images -o yaml
kubectl get nodes -L kubernetes.io/arch
```

The Pipeline currently has only `deploy`. The prepared `report-outcome`
Task is not yet connected. The deploy Task patches
`starfleet/scout-scan`, which has zero replicas. The reader pod mounts
retained storage; Task pods will mount the same claim. No check passes yet.

## Step 2: Write the inventory and scan Task

Save this as `task-scan-release-image.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: scan-release-image
  namespace: pipelines
spec:
  params:
  - name: image
    type: string
  - name: platform
    type: string
  - name: evidence-directory
    type: string
  workspaces:
  - name: evidence
  results:
  - name: outcome
    description: pass or fail after a completed HIGH,CRITICAL scan
  steps:
  - name: scan
    image: aquasec/trivy:0.76.2
    env:
    - name: IMAGE
      value: $(params.image)
    - name: PLATFORM
      value: $(params.platform)
    - name: EVIDENCE
      value: $(workspaces.evidence.path)/$(params.evidence-directory)
    script: |
      #!/bin/sh
      set -eu
      mkdir -p "$EVIDENCE"
      printf '%s\n' "$IMAGE" > "$EVIDENCE/image.txt"
      trivy image --image-src remote --platform "$PLATFORM" \
        --format cyclonedx --output "$EVIDENCE/sbom.cdx.json" "$IMAGE"
      trivy image --cache-dir "$EVIDENCE/cache" --download-db-only
      cp "$EVIDENCE/cache/db/metadata.json" "$EVIDENCE/database.json"
      if trivy image --image-src remote --platform "$PLATFORM" \
        --cache-dir "$EVIDENCE/cache" --skip-db-update --scanners vuln \
        --severity HIGH,CRITICAL --ignorefile '' --exit-code 42 \
        --format json --output "$EVIDENCE/scan.json" "$IMAGE"; then
        printf pass > "$(results.outcome.path)"
      else
        scan_status=$?
        printf fail > "$(results.outcome.path)"
        [ "$scan_status" -eq 42 ] || exit "$scan_status"
      fi
      rm -rf "$EVIDENCE/cache"

```

The three parameters identify the image, platform and run directory.
`workspaces` declares the mounted storage, and `results` declares the small
value exported to the Pipeline. Environment variables pass the inputs to
the shell without placing image text directly in the script.

The first Trivy command writes CycloneDX JSON without vulnerability scanning.
The next command downloads the database into this run's cache; `cp` retains
its metadata. The final command scans the image using that cache, keeps
`HIGH,CRITICAL` findings and disables ignore-file loading. Exit code `42`
means selected findings: the script writes `fail` and still succeeds.
A scanner error has another nonzero code and fails the Task. The script
removes the large cache only after a completed scan; the evidence remains.

Apply it:

```sh
kubectl apply -f task-scan-release-image.yaml
```

Then check the result:

```sh
kubectl -n pipelines get task scan-release-image -o yaml
```

The watch terminal still reports `vulnerability-gate` failing: the Pipeline
has not yet called the Task or gated deployment. It grades the complete
behavior rather than Task existence.

## Step 3: Connect the check and the deploy condition

Save this as `pipeline-release-scan-gate.yaml`:

```yaml
apiVersion: tekton.dev/v1
kind: Pipeline
metadata:
  name: release-scan-gate
  namespace: pipelines
spec:
  params:
  - name: image
    type: string
  - name: platform
    type: string
  workspaces:
  - name: evidence
  tasks:
  - name: check
    taskRef:
      name: scan-release-image
    params:
    - name: image
      value: $(params.image)
    - name: platform
      value: $(params.platform)
    - name: evidence-directory
      value: $(context.pipelineRun.name)
    workspaces:
    - name: evidence
      workspace: evidence
  - name: deploy
    taskRef:
      name: deploy-scanned-release
    params:
    - name: image
      value: $(params.image)
    when:
    - input: $(tasks.check.results.outcome)
      operator: in
      values:
      - pass
  finally:
  - name: report
    taskRef:
      name: report-outcome
    params:
    - name: pipeline-status
      value: $(tasks.status)
    - name: check-status
      value: $(tasks.check.status)
```

`params` declares the shared release inputs. The `check` Task receives both
inputs and the PipelineRun name, which gives each run its own directory.
The workspace mapping mounts the Pipeline's `evidence` into the Task.
`deploy` receives the same image and waits for the result through its
`when` reference. Only the string `pass` selects deployment; `runAfter`
alone would not test that string. The `finally` Task uses execution status,
so a scan verdict of `fail` still reports a successful check Task. Aggregate
status is `Succeeded` for the clean run and `Completed` when deploy is skipped.
The prepared report Task prints both values. If inventory fails, the check
Task fails and finally reports `Failed` for both statuses. The grader also
tries the same clean digest with an unavailable platform to prove this path.

Apply it:

```sh
kubectl apply -f pipeline-release-scan-gate.yaml
```

Then check the result:

```sh
kubectl -n pipelines get pipelineruns
kubectl -n pipelines get taskruns
kubectl -n pipelines exec release-scan-reader -- find /evidence -maxdepth 2 -type f
```

The watch terminal should now show `vulnerability-gate` passing after its
three runs finish. Its messages confirm a clean deployment, a vulnerable
release skipped with a successful check Task, retained inventories, and an
inventory error that prevents deployment while finally still reports.
Database downloads can take several minutes. The grader removes its
PipelineRuns after reading their status, so use your own run below to
inspect a retained run's result.

## Step 4: Inspect your own run and saved evidence

Once the watch passes, stop it with Ctrl-C before starting your own run,
so the grader does not change the Deployment at the same time. Save this
as `pipelinerun-scan-clean.yaml`. Replace `linux/amd64` with
`linux/arm64` if that matches your node:

```yaml
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: scan-clean-
  namespace: pipelines
spec:
  pipelineRef:
    name: release-scan-gate
  taskRunTemplate:
    serviceAccountName: scan-runner
  timeouts:
    pipeline: 10m0s
  params:
    - name: image
      value: docker.io/library/hello-world@sha256:5e22040d441e5fb3aed38368acbe8486b575d7018df38dbdfbc7311fbb2ef3a9
    - name: platform
      value: linux/amd64
  workspaces:
    - name: evidence
      persistentVolumeClaim:
        claimName: release-scan-evidence
```

`pipelineRef` selects the Pipeline. `taskRunTemplate` selects its service
account, `timeouts` bounds the run, and `params` supplies the immutable
image and platform. The workspace binding reuses the existing claim
rather than allocating temporary storage. Apply it by creating a new run;
`generateName` requires `create` rather than `apply`:

```sh
kubectl create -f pipelinerun-scan-clean.yaml
kubectl -n pipelines get pipelineruns
kubectl -n pipelines get taskruns -o yaml
```

Read the created run name and wait for its condition to become successful.
Find `outcome: pass` in its check TaskRun's results. Replace `<RUN-NAME>`
with that actual run name to read its evidence:

```sh
kubectl -n pipelines exec release-scan-reader -- cat /evidence/<RUN-NAME>/sbom.cdx.json
kubectl -n pipelines exec release-scan-reader -- cat /evidence/<RUN-NAME>/database.json
```

Look for the full clean image reference in `metadata.component.name` and
an `UpdatedAt` field in the database metadata. The clean fixture contains
no packages, so an empty component inventory is valid for this image.

To try the blocked path, change the file's `generateName` to `scan-blocked-`
and its image value to this reference, keeping the same platform and claim:

```text
docker.io/library/alpine@sha256:c19173c5ada610a5989151111163d28a67368362762534d8a8121ce95cf2bd5a
```

Create it again with the same `kubectl create` command. Inspect its check
TaskRun for `outcome: fail` and its PipelineRun for `status.skippedTasks`
containing `deploy`. The check Task still succeeds. Read the first run's
SBOM again after the blocked run finishes: a new directory must not
overwrite the earlier file. Restart the watch command from the top of
this walkthrough after your runs finish. It should show `vulnerability-gate`
passing again.

## Step 5: Verify the candidates

Read the starting labels and candidates, then verify each immutable reference:

```sh
kubectl get namespaces starfleet starfleet-prod starfleet-canary outpost outpost-unlabelled -L environment
kubectl -n starfleet get configmap signature-candidates -o yaml
cosign verify --key /tmp/ats021-capstone-050-02-signatures/audit-signing.pub --insecure-ignore-tlog ghcr.io/kyverno/test-verify-image@sha256:b31bfb4d0213f254d361e0079deaaebefa4f82ba7aa76ef82e90b4935ad5b105
echo $?
cosign verify --key /tmp/ats021-capstone-050-02-signatures/audit-signing.pub --insecure-ignore-tlog ghcr.io/kyverno/test-verify-image@sha256:74a98f0e4d750c9052f092a7f7a72de7b20f94f176a490088f7a744c76c53ea5
echo $?
```

Look for a verified payload whose digest matches the scout reference and a
zero exit code. For probe, look for a nonzero status and a signature
verification failure. A registry connection failure is not evidence that
an image is unsigned. Restore registry access before recording an answer.
`vulnerability-gate` remains passing in the watch terminal. The signature
checks still fail because the answer and policy are absent.

The public key verifies the signature; the private key is not needed.
`--insecure-ignore-tlog` skips transparency-log verification for this public
test fixture. It does not skip checking the image digest or signature.

## Step 6: Record the results

A ConfigMap stores non-secret strings. Save this as
`configmap-signature-audit.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: signature-audit
  namespace: starfleet
data:
  signed-image: ghcr.io/kyverno/test-verify-image@sha256:b31bfb4d0213f254d361e0079deaaebefa4f82ba7aa76ef82e90b4935ad5b105
  unsigned-image: ghcr.io/kyverno/test-verify-image@sha256:74a98f0e4d750c9052f092a7f7a72de7b20f94f176a490088f7a744c76c53ea5
```

The `metadata` fields name and scope the object. The two `data` strings
record complete immutable references rather than candidate names. Apply it:

```sh
kubectl apply -f configmap-signature-audit.yaml
```

Then check the result:

```sh
kubectl -n starfleet get configmap signature-audit -o yaml
```

The watch terminal now shows `signature-evidence` passing. It compares the
answers with fresh cosign verification, so registry access is still needed.

## Step 7: Enforce verification in production

Save this as `imagevalidatingpolicy-signed-production.yaml`:

```yaml
apiVersion: policies.kyverno.io/v1
kind: ImageValidatingPolicy
metadata:
  name: signed-production
spec:
  evaluation:
    background:
      enabled: false
  webhookConfiguration:
    timeoutSeconds: 30
  failurePolicy: Fail
  validationActions: [Deny]
  matchConstraints:
    namespaceSelector:
      matchLabels:
        environment: production
    resourceRules:
      - apiGroups: [""]
        apiVersions: [v1]
        operations: [CREATE, UPDATE]
        resources: [pods, pods/ephemeralcontainers]
  matchImageReferences:
    - glob: "*"
  validationConfigurations:
    mutateDigest: false
    verifyDigest: true
    required: true
  attestors:
    - name: auditKey
      cosign:
        key:
          data: |
              -----BEGIN PUBLIC KEY-----
              MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE8nXRh950IZbRj8Ra/N9sbqOPZrfM
              5/KAQN0/KjHcorm/J5yctVd7iEcnessRQjU917hmKO6JWVGHpDguIyakZA==
              -----END PUBLIC KEY-----
        ctlog:
          insecureIgnoreTlog: true
  validations:
    - expression: >-
        (images.containers + images.initContainers + images.ephemeralContainers).map(image,
          verifyImageSignatures(image, [attestors.auditKey])).all(count, count > 0)
      message: Every image must have a signature from the approved key.
```

The namespace selector matches labels, so it protects both production
namespaces and any later namespace with the same label. The resource rules
cover Pod creation, updates and the ephemeral-container subresource used
for debug containers. The image glob selects every image in that scope.

`attestors.auditKey` supplies the trusted public key. The Common Expression
Language (CEL) expression checks regular, init and ephemeral container
images and requires a positive signature count for each. `required` requires
verification, `verifyDigest` requires digests, and `mutateDigest: false`
leaves tag references unchanged so they cannot satisfy that requirement.
`Deny` rejects failed validations; `Fail` refuses requests on evaluation
errors. Background evaluation is disabled because this task tests admission.

Apply it:

```sh
kubectl apply -f imagevalidatingpolicy-signed-production.yaml
```

Then check the result:

```sh
kubectl get imagevalidatingpolicy signed-production -o yaml
kubectl -n kyverno get deployments
```

Wait for `status.conditionStatus.ready` to become true. Read
`status.conditionStatus.conditions` if it stays false. The watch terminal
now shows `production-admission` and `namespace-scope` passing once the
webhook uses the policy. It also keeps `signature-evidence` passing.

## Step 8: Prove admission and scope

Server-side dry runs execute admission without saving Pods or pulling their
images onto a node. Use the existing `scout` service account in each request:

```sh
kubectl -n starfleet-prod run signed-check --image=ghcr.io/kyverno/test-verify-image@sha256:b31bfb4d0213f254d361e0079deaaebefa4f82ba7aa76ef82e90b4935ad5b105 --overrides='{"spec":{"serviceAccountName":"scout"}}' --dry-run=server
kubectl -n starfleet-prod run unsigned-check --image=ghcr.io/kyverno/test-verify-image@sha256:74a98f0e4d750c9052f092a7f7a72de7b20f94f176a490088f7a744c76c53ea5 --overrides='{"spec":{"serviceAccountName":"scout"}}' --dry-run=server
kubectl -n starfleet-canary run signed-check --image=ghcr.io/kyverno/test-verify-image@sha256:b31bfb4d0213f254d361e0079deaaebefa4f82ba7aa76ef82e90b4935ad5b105 --overrides='{"spec":{"serviceAccountName":"scout"}}' --dry-run=server
kubectl -n starfleet-canary run unsigned-check --image=ghcr.io/kyverno/test-verify-image@sha256:74a98f0e4d750c9052f092a7f7a72de7b20f94f176a490088f7a744c76c53ea5 --overrides='{"spec":{"serviceAccountName":"scout"}}' --dry-run=server
kubectl -n outpost run signed-check --image=ghcr.io/kyverno/test-verify-image@sha256:b31bfb4d0213f254d361e0079deaaebefa4f82ba7aa76ef82e90b4935ad5b105 --overrides='{"spec":{"serviceAccountName":"scout"}}' --dry-run=server
kubectl -n outpost run unsigned-check --image=ghcr.io/kyverno/test-verify-image@sha256:74a98f0e4d750c9052f092a7f7a72de7b20f94f176a490088f7a744c76c53ea5 --overrides='{"spec":{"serviceAccountName":"scout"}}' --dry-run=server
kubectl -n outpost-unlabelled run signed-check --image=ghcr.io/kyverno/test-verify-image@sha256:b31bfb4d0213f254d361e0079deaaebefa4f82ba7aa76ef82e90b4935ad5b105 --overrides='{"spec":{"serviceAccountName":"scout"}}' --dry-run=server
kubectl -n outpost-unlabelled run unsigned-check --image=ghcr.io/kyverno/test-verify-image@sha256:74a98f0e4d750c9052f092a7f7a72de7b20f94f176a490088f7a744c76c53ea5 --overrides='{"spec":{"serviceAccountName":"scout"}}' --dry-run=server
```

Look for signed acceptance and an unsigned refusal naming `signed-production`
in both production namespaces. Both requests must succeed in each other
namespace. All four watch checks remain passing; this step makes their
admission evidence visible in your own terminal.

If production accepts the unsigned reference, check `validationActions`,
the namespace selector and policy readiness. If the signed reference fails,
read the API server's response and inspect controller logs:

```sh
kubectl -n kyverno logs deployment/kyverno-admission-controller --all-containers --tail=80
```

A timeout is not a signature verdict. Check registry access and the copied
public key. If either outside namespace refuses an image, correct the
namespace selector rather than changing its labels or disabling enforcement.

## Step 9: Submit

Confirm `vulnerability-gate`, `signature-evidence`, `production-admission`
and `namespace-scope` pass in the watch terminal. Stop the watch with
Ctrl-C, then finish the attempt once:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-050/capstone/labs/lab-02
```

A pass or fail finishes the attempt and deletes the lab.

## If a check stays red

- **`vulnerability-gate`: scan findings fail the Task.** Handle exit code
  `42` as the `fail` verdict. Other nonzero codes remain Task failures.
- **`vulnerability-gate`: report is missing.** Put `report` in `finally`,
  passing the two execution status variables. Do not guard it on a result.
- **`vulnerability-gate`: evidence differs or disappears.** Pass the same
  image to both Tasks, use the persistent claim and name directories after
  runs. Restore registry or database access if a download fails.
- **`signature-evidence`: verification fails.** Check the public key and
  registry access. A network error does not prove an image is unsigned.
- **`production-admission`: unsigned is admitted.** Check policy readiness,
  `Deny`, the trusted key and the production label selector.
- **`namespace-scope`: outside requests are refused.** Correct the selector;
  keep namespace labels and production enforcement intact.
