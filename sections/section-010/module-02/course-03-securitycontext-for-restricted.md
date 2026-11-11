# A securityContext That Passes Restricted

The warnings in `starfleet` already name the fields `scout` needs. This part turns that list into a `securityContext`, explains what each field does on the node, and deals with one more error that only appears after admission has accepted the pod. At the end, `scout` passes `restricted` and runs.

## Pod fields and container fields

A `securityContext` exists at two places in a pod spec. `spec.securityContext` applies to the whole pod. `spec.containers[].securityContext` applies to one container and wins over the pod value for the same field. Some fields exist only at one place. The `restricted` level checks four settings:

| Field | Where | What it does on the node |
| --- | --- | --- |
| `allowPrivilegeEscalation: false` | container | Sets the Linux `no_new_privs` flag, so a process cannot gain more rights than its parent, for example through a `setuid` program |
| `capabilities.drop: ["ALL"]` | container | Removes every Linux capability (small pieces of root's power, such as binding low ports or changing file owners). `restricted` allows adding back only `NET_BIND_SERVICE` |
| `runAsNonRoot: true` | pod or container | Makes the kubelet refuse to start the container if it would run as user ID `0` |
| `seccompProfile.type: RuntimeDefault` | pod or container | Turns on the container runtime's default seccomp profile, which blocks rarely used and dangerous system calls |

The messages say `pod or container` for the last two, so setting them once at pod level covers every container.

## Apply the fix

Here is the `scout` Deployment with those four settings. The pod-level part sets the user rules and seccomp for the whole pod; the container part drops capabilities and blocks privilege escalation.

<!-- astrona:playground:renew -->

Save this as `deployment-scout-restricted.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: scout
  namespace: starfleet
  labels:
    app: scout
spec:
  replicas: 1
  selector:
    matchLabels:
      app: scout
  template:
    metadata:
      labels:
        app: scout
    spec:
      serviceAccountName: scout
      securityContext:
        runAsNonRoot: true
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: scout
          image: ghcr.io/stefanprodan/podinfo:6.15.0
          ports:
            - name: http
              containerPort: 9898
          readinessProbe:
            httpGet:
              path: /readyz
              port: http
          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              drop: ["ALL"]
          resources:
            requests:
              cpu: 10m
              memory: 32Mi
            limits:
              memory: 64Mi
```

Apply it and watch the rollout:

```sh
kubectl apply -f deployment-scout-restricted.yaml
kubectl -n starfleet rollout status deployment scout --timeout=90s
kubectl -n starfleet get pods -l app=scout
```

You should see something like:

```text
deployment.apps/scout configured
Waiting for deployment "scout" rollout to finish: 1 old replicas are pending termination...
error: timed out waiting for the condition
NAME                     READY   STATUS                       RESTARTS   AGE
scout-5596cbbbd5-284c7   1/1     Running                      0          108s
scout-7b754994cb-zzkjd   0/1     CreateContainerConfigError   0          90s
```

There was no `warn` warning this time, so admission accepted the new pod template at `restricted`. The new pod was created, but it never started.

## The check the kubelet adds

`CreateContainerConfigError` means the kubelet, the agent on the node that starts containers, refused to build the container. Its reason is in the pod's events:

```sh
kubectl -n starfleet describe pod -l app=scout | grep Failed
```

The relevant line is (shortened):

```text
  Warning  Failed     4s (x9 over 95s)  kubelet            spec.containers{scout}: Error: container has runAsNonRoot and image has non-numeric user (app), cannot verify user is non-root ...
```

`runAsNonRoot: true` is checked in two places. Admission checks that the field is set. The kubelet checks the user the container will actually run as. The `podinfo` image declares its user by name, `app`, and the kubelet cannot know which user ID a name stands for inside the image, so it refuses to start the container rather than guess. The fix is to give the user ID explicitly. The `app` user in this image has the ID `100`, which you can see by running `id` in the old pod (`kubectl -n starfleet exec deploy/scout -- id` prints `uid=100(app) gid=101(app) groups=101(app)`).

In `deployment-scout-restricted.yaml`, add `runAsUser: 100` under the pod's `securityContext`, so that part reads:

```yaml
      securityContext:
        runAsNonRoot: true
        runAsUser: 100
        seccompProfile:
          type: RuntimeDefault
```

Apply it again:

```sh
kubectl apply -f deployment-scout-restricted.yaml
kubectl -n starfleet rollout status deployment scout --timeout=90s
kubectl -n starfleet exec deploy/scout -- id
```

You should see something like:

```text
deployment.apps/scout configured
Waiting for deployment "scout" rollout to finish: 1 old replicas are pending termination...
deployment "scout" successfully rolled out
uid=100(app) gid=101(app) groups=101(app)
```

## Prove it against the level

Run the dry run for `restricted` once more:

```sh
kubectl label --dry-run=server --overwrite namespace starfleet pod-security.kubernetes.io/enforce=restricted
```

You should see something like:

```text
Warning: existing pods in namespace "starfleet" violate the new PodSecurity enforce level "restricted:v1.35"
Warning: privileged-debug-748b7d59f4-8qx5g: privileged, allowPrivilegeEscalation != false, unrestricted capabilities, restricted volume types, runAsNonRoot != true, seccompProfile
Warning: probe-6f569ff97-mftq2 (and 1 other pod): allowPrivilegeEscalation != false, unrestricted capabilities, runAsNonRoot != true, seccompProfile
namespace/starfleet labeled (server dry run)
```

`scout` is gone from the list: the group is now `probe` and one other pod, `shuttle`. The same four settings fix those two, and removing `privileged-debug` clears the last line. When the dry run prints only the final `labeled (server dry run)` line, `starfleet` is ready for `enforce: restricted`.

You can now write a `securityContext` that passes `restricted`, say what each field does on the node, and tell an admission rejection from a kubelet refusal. A pod can pass admission and still fail to start when the image's user is a name, and `runAsUser` with the numeric ID fixes it.

## Common pitfalls

> [!WARNING]
> - **Setting `capabilities.drop` at pod level.** It exists only on containers. Set it on every container, including init containers.
> - **Stopping after admission accepts the pod.** `runAsNonRoot` is checked again by the kubelet; a non-numeric image user gives `CreateContainerConfigError`.
> - **Using `runAsUser: 0` to make an image work.** `restricted` rejects it, and so does the kubelet with `runAsNonRoot: true`. Fix the image or pick its non-root user ID.
> - **Fixing only the containers you know about.** The warning names every container, including sidecars and init containers; read the whole message.
