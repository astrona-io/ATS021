# Summary

RBAC decides who may create a pod. Pod Security Admission decides which pods may be created at all, by checking each new pod against a level chosen per namespace.

## What you learned

The Pod Security Standards have three cumulative levels. `privileged` allows everything. `baseline` blocks settings known to break isolation, such as privileged containers, `hostPath` volumes and host networking. `restricted` also requires every container to block privilege escalation, drop all capabilities, run as non-root and use a seccomp profile. A namespace without labels checks nothing.

A namespace label `pod-security.kubernetes.io/<mode>: <level>` sets a level per mode. `enforce` rejects pods, `warn` returns a warning to the client and also checks workload templates, and `audit` adds an annotation to the audit log. A `<mode>-version` label pins the checks to one Kubernetes version. A rejection says `violates PodSecurity "<level>:<version>"` and lists each failed check with the container and the field.

`kubectl label --dry-run=server` tests a new level against the pods that already run and prints each one that would break it. Enforcing a level does not touch running pods. When a Deployment's new pods are rejected, the Deployment is still accepted; the ReplicaSet records `FailedCreate` events, and the Deployment shows `ReplicaFailure=True` while the old pods keep running.

A `securityContext` exists at pod level and container level, and the container value wins. The kubelet checks `runAsNonRoot` again when it starts the container and refuses an image whose user is a name, with `CreateContainerConfigError`; `runAsUser` with the numeric user ID fixes it. The key facts to remember are these:

- Only `enforce` blocks; `warn` and `audit` report.
- Run a server-side dry run of the label before every level change.
- A rejected controller pod shows up as `FailedCreate` on the ReplicaSet, not on your command.
- Fix the pod template, never the namespace level, when a workload is rejected.

<!-- astrona:playground:destroy -->
