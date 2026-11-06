# Solution

Add the scan Task on `terminal`, connect its result to deployment, and keep
both releases' evidence in a persistent workspace. A software bill of
materials (SBOM) records the detected inventory; the scan report records
known vulnerabilities at scan time.

| Goal | Tekton field or file |
| --- | --- |
| Keep the inventory | `evidence` workspace, one directory per run |
| Export the decision | `outcome` result |
| Select deployment | `when` on `$(tasks.check.results.outcome)` |
| Explain the decision | `scan.json` and `database.json` |

Keep this command running in a second host terminal. It grades the lab every few seconds and records nothing:

```sh
astrona submit --watch --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-050/module-03/labs/lab-02
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

The Pipeline currently has only `deploy`. The deploy Task patches
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
```

`params` declares the shared release inputs. The `check` Task receives both
inputs and the PipelineRun name, which gives each run its own directory.
The workspace mapping mounts the Pipeline's `evidence` into the Task.
`deploy` receives the same image and waits for the result through its
`when` reference. Only the string `pass` selects deployment; `runAfter`
alone would not test that string.

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
two runs finish. Its messages confirm a clean deployment, a vulnerable
release skipped with a successful check Task, and retained inventories.
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

## Step 5: Submit

Confirm `vulnerability-gate` passes in the watch terminal. Stop the watch
with Ctrl-C, then finish the attempt once:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-050/module-03/labs/lab-02
```

A pass or fail finishes the attempt and deletes the lab.

## If the check stays red

- **A scan reports findings but the Task fails.** Capture exit code `42`
  inside the conditional and publish `fail` without returning that code.
- **Deploy starts for a vulnerable image.** Read `when.input`; it must use
  the check Task's result, with only `pass` in `values`.
- **A database or registry download fails.** Read the scan step logs and
  restore network access. Keep this as a Task failure; do not publish `pass`.
- **The saved inventory names another image or disappears.** Pass the same
  image into both Tasks, bind the existing PVC, and use the run name as
  the evidence directory. An `emptyDir` disappears with its pod.
