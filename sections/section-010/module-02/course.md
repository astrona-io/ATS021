# Restrict Pods With Pod Security Admission

RBAC decides who may create a pod. It does not look at what the pod asks for. A user who may create pods in a namespace may, by default, also create a privileged pod that mounts the node's root file system, and from there control the node. Pod Security Admission closes that gap. It is an admission controller built into the API server: it checks every pod against one of three Pod Security Standards levels and rejects, warns about or records the ones that break it.

Keep one sentence in mind for this module: **a namespace label picks a level and a mode, and the API server checks every new pod against it.** You will read the label that already protects one namespace, test a stricter level against running workloads before you turn it on, fix a workload so it passes the strictest level, and find out where the rejection hides when a Deployment, not a person, creates the pod.

The four readings cover security levels and admission rejections, inspection of existing violations, staged namespace enforcement, and the securityContext fields required by restricted admission.

The independent labs cover staged warning and enforcement labels, reviewing baseline violations across three namespaces, and repairing workloads for restricted admission.

The readings separate existing-workload inspection from staged namespace enforcement. Practise the inventory before changing enforce, warn and audit labels, then repair workload security contexts.

## Learning objectives

After this module you can:

- Label a namespace to enforce, audit or warn at the `baseline` or `restricted` Pod Security Standards level.
- Read a Pod Security Admission rejection and name each field that breaks the level.
- Write a `securityContext` (`runAsNonRoot`, `allowPrivilegeEscalation`, `capabilities` drop `ALL`, `seccompProfile` `RuntimeDefault`) that passes `restricted`.
- Test a level change against existing workloads with a server-side dry run before enforcing it.
- Find a baseline violation across several namespaces and label the namespace for review.
- Explain why a Deployment is accepted while its pods are rejected, and find the error in the ReplicaSet events.

## Before you start

You need Kubernetes basics: namespaces, pods, Deployments and ReplicaSets, labels, and the commands `kubectl get`, `kubectl apply`, `kubectl describe` and `kubectl label`. You do not need any policy engine; Pod Security Admission is built into Kubernetes and on by default.

Your playground is a single-node `kind` cluster running Kubernetes 1.35, with no extra tools:

| Namespace | What is in it |
| --- | --- |
| `starfleet` | No Pod Security labels. The example workloads `scout`, `probe` and `shuttle` run with no `securityContext`. A `privileged-debug` Deployment runs a privileged container with the node's root file system mounted at `/host`. It is there on purpose |
| `outpost` | Labelled `pod-security.kubernetes.io/enforce: baseline`. The `drifter` client runs here |

`kubectl` already points at the playground cluster, as the cluster administrator.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
