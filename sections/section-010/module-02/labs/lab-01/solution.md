# Solution

Solve this lab on `terminal`. The output below comes from a real run of this lab.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-010/module-02/labs/lab-01
```

Keep this command running in a second host terminal. It grades the lab every few seconds and records nothing:

```sh
astrona submit --watch --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-010/module-02/labs/lab-01
```

Use `--watch` until the end, because a plain `astrona submit` finishes the attempt and deletes the lab. Run the plain command once, in the last step.

## Step 1: Find what restricted would reject

A server-side dry run of the label shows which pods break the level, without changing anything:

```sh
kubectl label --dry-run=server --overwrite namespace starfleet pod-security.kubernetes.io/enforce=restricted
```

You should see something like:

```text
Warning: existing pods in namespace "starfleet" violate the new PodSecurity enforce level "restricted:latest"
Warning: privileged-debug-748b7d59f4-mk5mn: privileged, allowPrivilegeEscalation != false, unrestricted capabilities, restricted volume types, runAsNonRoot != true, seccompProfile
Warning: probe-6f569ff97-q8rvr (and 2 other pods): allowPrivilegeEscalation != false, unrestricted capabilities, runAsNonRoot != true, seccompProfile
namespace/starfleet labeled (server dry run)
```

`privileged-debug` breaks the most rules, and `probe`, `scout` and `shuttle` all miss the four settings. Do not label the namespace yet. Pods that already run keep running after a label, so the label alone changes nothing about them, and every later restart would be rejected.

## Step 2: Delete privileged-debug

```sh
kubectl -n starfleet delete deployment privileged-debug
```

You should see:

```text
deployment.apps "privileged-debug" deleted from starfleet namespace
```

Its pod needs `privileged: true` and a `hostPath` volume, so it cannot be made to pass `restricted`.

## Step 3: Add the securityContext to the three workloads

A strategic merge patch changes the pod template and keeps the rest of each Deployment. The container name equals the Deployment name. The images of `scout` and `shuttle` declare their user by name only (`app` and `curl_user`), so they need `runAsUser: 100`: the kubelet refuses `runAsNonRoot: true` with a non-numeric image user. The `probe` image already uses the numeric user `65532`.

```sh
kubectl -n starfleet patch deployment scout -p '{"spec":{"template":{"spec":{"securityContext":{"runAsNonRoot":true,"runAsUser":100,"seccompProfile":{"type":"RuntimeDefault"}},"containers":[{"name":"scout","securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]}}}]}}}}'
kubectl -n starfleet patch deployment probe -p '{"spec":{"template":{"spec":{"securityContext":{"runAsNonRoot":true,"runAsUser":65532,"seccompProfile":{"type":"RuntimeDefault"}},"containers":[{"name":"probe","securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]}}}]}}}}'
kubectl -n starfleet patch deployment shuttle -p '{"spec":{"template":{"spec":{"securityContext":{"runAsNonRoot":true,"runAsUser":100,"seccompProfile":{"type":"RuntimeDefault"}},"containers":[{"name":"shuttle","securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]}}}]}}}}'
```

You should see:

```text
deployment.apps/scout patched
deployment.apps/probe patched
deployment.apps/shuttle patched
```

Wait for the rollouts:

```sh
kubectl -n starfleet rollout status deployment/scout
kubectl -n starfleet rollout status deployment/probe
kubectl -n starfleet rollout status deployment/shuttle
```

Each command ends with a line like `deployment "scout" successfully rolled out`.

The watch terminal now shows the checks `privileged-debug-removed`, `workloads-comply-and-run` and `scout-still-serves` passing.

## Step 4: Enforce restricted

```sh
kubectl label --overwrite namespace starfleet pod-security.kubernetes.io/enforce=restricted
```

You should see `namespace/starfleet labeled`, with no warning about existing pods. Prove that the API server now refuses a privileged pod. Save this as `pod-privileged-test.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: privileged-test
  namespace: starfleet
spec:
  containers:
    - name: debug
      image: curlimages/curl:8.22.0
      command: ["sleep", "30"]
      securityContext:
        privileged: true
```

Send it to the API server as a dry run, so nothing is created:

```sh
kubectl apply --dry-run=server -f pod-privileged-test.yaml
```

You should see something like (shortened):

```text
Error from server (Forbidden): error when creating "pod-privileged-test.yaml": pods "privileged-test" is forbidden: violates PodSecurity "restricted:latest": privileged (container "debug" must not set securityContext.privileged=true), allowPrivilegeEscalation != false (container "debug" must set securityContext.allowPrivilegeEscalation=false) ...
```

Press Ctrl-C to stop the watch, then run the grader once:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-010/module-02/labs/lab-01
```

You should see `5 passed, 0 failed` and `PROCTOR: PASS`. Then remove the lab:

```sh
astrona destroy ats-021-lab-010-02
```
