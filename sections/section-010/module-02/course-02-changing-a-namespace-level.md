# Changing A Namespace Level Safely

Turning on `enforce: restricted` in a busy namespace looks harmless: the running pods keep running. The damage comes later. The next time a Deployment rolls out, a node drains or a pod crashes, the replacement pods are rejected, and the application slowly disappears. This part raises the level of `starfleet` in the safe order: test the change, report before blocking, then enforce, and find where the rejection shows up when a controller creates the pods.

## Test the change before you make it

A namespace label change goes through the API server like any other request. With `--dry-run=server`, Pod Security Admission checks every existing pod in the namespace against the new level and prints a warning for each one that would break it. Nothing is changed.

<!-- astrona:playground:renew -->

```sh
kubectl label --dry-run=server --overwrite namespace starfleet pod-security.kubernetes.io/enforce=restricted
```

You should see something like:

```text
Warning: existing pods in namespace "starfleet" violate the new PodSecurity enforce level "restricted:latest"
Warning: privileged-debug-748b7d59f4-8qx5g: privileged, allowPrivilegeEscalation != false, unrestricted capabilities, restricted volume types, runAsNonRoot != true, seccompProfile
Warning: probe-6f569ff97-mftq2 (and 2 other pods): allowPrivilegeEscalation != false, unrestricted capabilities, runAsNonRoot != true, seccompProfile
namespace/starfleet labeled (server dry run)
```

Every pod in `starfleet` breaks `restricted`. Pods with the same failures are grouped: `probe` stands for itself, `scout` and `shuttle`, which miss the same four settings. Now test `baseline`:

```sh
kubectl label --dry-run=server --overwrite namespace starfleet pod-security.kubernetes.io/enforce=baseline
```

You should see something like:

```text
Warning: existing pods in namespace "starfleet" violate the new PodSecurity enforce level "baseline:latest"
Warning: privileged-debug-748b7d59f4-8qx5g: hostPath volumes, privileged
namespace/starfleet labeled (server dry run)
```

Only `privileged-debug` breaks `baseline`. The ordinary workloads pass it unchanged, which is typical. That gives a plan: enforce `baseline` now, and report `restricted` until the workloads are fixed.

## Report first, then enforce

The `warn` and `audit` modes report without blocking. Each mode can also take a version label. `pod-security.kubernetes.io/warn-version: v1.35` pins the checks to the ones in Kubernetes 1.35, so a cluster upgrade cannot add a new check and start rejecting pods without anyone changing the namespace. Without a version label, the level uses `latest`.

Label `starfleet` to warn and audit at `restricted`:

```sh
kubectl label --overwrite namespace starfleet pod-security.kubernetes.io/warn=restricted pod-security.kubernetes.io/warn-version=v1.35 pod-security.kubernetes.io/audit=restricted
```

`warn` also checks workload objects such as Deployments, not only pods. Restart the `scout` Deployment, which changes its pod template:

```sh
kubectl -n starfleet rollout restart deployment scout
```

You should see:

```text
Warning: would violate PodSecurity "restricted:v1.35": allowPrivilegeEscalation != false (container "scout" must set securityContext.allowPrivilegeEscalation=false), unrestricted capabilities (container "scout" must set securityContext.capabilities.drop=["ALL"]), runAsNonRoot != true (pod or container "scout" must set securityContext.runAsNonRoot=true), seccompProfile (pod or container "scout" must set securityContext.seccompProfile.type to "RuntimeDefault" or "Localhost")
deployment.apps/scout restarted
```

The restart succeeded, and the warning lists the exact fields the `scout` pods need for `restricted`. A team that deploys into this namespace now sees what to fix every time they deploy, and nothing breaks yet.

Now enforce `baseline`, pinned to the same version:

```sh
kubectl label --overwrite namespace starfleet pod-security.kubernetes.io/enforce=baseline pod-security.kubernetes.io/enforce-version=v1.35
kubectl -n starfleet get pods -l app=privileged-debug
```

You should see something like:

```text
Warning: existing pods in namespace "starfleet" violate the new PodSecurity enforce level "baseline:v1.35"
Warning: privileged-debug-748b7d59f4-8qx5g: hostPath volumes, privileged
namespace/starfleet labeled
NAME                                READY   STATUS    RESTARTS   AGE
privileged-debug-748b7d59f4-8qx5g   1/1     Running   0          58s
```

The label is set, and the warning is the same as in the dry run. The privileged pod is still `Running`. Admission checks requests, and a pod that already exists makes no request.

## When a controller creates the pod

Restart `privileged-debug`. The Deployment needs a new pod, which `enforce` must now reject:

```sh
kubectl -n starfleet rollout restart deployment privileged-debug
kubectl -n starfleet get deployment privileged-debug
kubectl -n starfleet get replicasets -l app=privileged-debug
```

You should see something like (the `warn` warning before `restarted` is left out here):

```text
deployment.apps/privileged-debug restarted
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
privileged-debug   1/1     0            1           64s
NAME                          DESIRED   CURRENT   READY   AGE
privileged-debug-748b7d59f4   1         1         1       64s
privileged-debug-77f89c67c7   1         0         0       6s
```

`kubectl rollout restart` reported success, because the Deployment itself was accepted: Pod Security Admission does not enforce on Deployments, only on pods. The Deployment controller then created a new ReplicaSet, `privileged-debug-77f89c67c7`, which wants one pod and has zero. The old pod still serves traffic, so nothing looks broken from the outside.

The ReplicaSet controller is the component that sends the pod create request, so the rejection lands in its events:

```sh
kubectl -n starfleet describe replicaset privileged-debug-77f89c67c7
```

The end of the output looks like this (shortened to two of the events):

```text
Events:
  Type     Reason        Age   From                   Message
  ----     ------        ----  ----                   -------
  Warning  FailedCreate  6s    replicaset-controller  Error creating: pods "privileged-debug-77f89c67c7-xjj6g" is forbidden: violates PodSecurity "baseline:v1.35": hostPath volumes (volume "host-root"), privileged (container "debug" must not set securityContext.privileged=true)
  Warning  FailedCreate  6s    replicaset-controller  Error creating: pods "privileged-debug-77f89c67c7-5xptc" is forbidden: violates PodSecurity "baseline:v1.35": hostPath volumes (volume "host-root"), privileged (container "debug" must not set securityContext.privileged=true)
```

The same message as before, now as a `FailedCreate` event from the `replicaset-controller`, repeated each time it tries again. The Deployment shows it too, as a condition. `kubectl -n starfleet get events --field-selector reason=FailedCreate` finds these events across the whole namespace, and the Deployment's `ReplicaFailure` condition carries the first message:

```sh
kubectl -n starfleet get deployment privileged-debug -o jsonpath='{range .status.conditions[*]}{.type}={.status} {.reason}{"\n"}{end}'
```

You should see:

```text
Available=True MinimumReplicasAvailable
Progressing=True NewReplicaSetCreated
ReplicaFailure=True FailedCreate
```

`Available=True` and `ReplicaFailure=True` at the same time is the signature of this problem: the old pods still run, and the new ones cannot be created. Fix the pod template, not the namespace label. For `privileged-debug`, the right fix is usually to delete it: a debug pod with the node's root file system mounted does not belong in an application namespace.

You can now test a level change with a dry run, report a stricter level with `warn` and `audit` while enforcing a looser one, and pin each mode to a Kubernetes version. You have also seen that a rejected pod from a Deployment shows up as `FailedCreate` events on the ReplicaSet, not as an error on your command. The open question is what the `restricted` level actually wants in the pod spec, so `starfleet` can enforce it.

## Common pitfalls

> [!WARNING]
> - **Enforcing a level without a dry run.** Running pods hide the problem until the next rollout or restart.
> - **Looking for the rejection on the Deployment command.** The Deployment is accepted; the ReplicaSet's `FailedCreate` events hold the error.
> - **Leaving levels unpinned.** Without `enforce-version`, an upgrade can add checks and reject pods that passed yesterday.
> - **Relaxing the namespace label to make a pod start.** That opens the namespace to every other unsafe pod too. Fix the pod template.
