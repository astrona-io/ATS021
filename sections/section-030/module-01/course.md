# Validate, Mutate And Generate With Kyverno

RBAC decides who may create an object, and Pod Security Admission checks a fixed list of pod fields. Platform rules go further: every container needs resource limits, every pod needs a team label, every new namespace starts with a default-deny NetworkPolicy. Kyverno is a policy engine that runs as an admission webhook and enforces rules like these, written as Kubernetes resources in YAML, with no programming language.

Keep one sentence in mind for this module: **a Kyverno rule selects objects with `match`, then validates, mutates or generates.** You will write a rule that blocks pods without limits, switch it between blocking and reporting and read the reports, add a default label with a mutate rule, and create a NetworkPolicy in every new namespace with a generate rule.

The module has three parts. **Validate Rules And Admission** writes the first ClusterPolicy, reads Kyverno's rejection, and shows how one pod rule also checks Deployments. **Enforce, Audit And Policy Reports** switches the rule to Audit and reads the PolicyReports that Kyverno writes for existing and new objects. **Mutate And Generate Rules** changes objects as they are created and creates new ones, and explains the state of policy exceptions in Kyverno 1.19.1.

## Learning objectives

After this module you can:

- Write a validate rule that rejects pods without resource limits in selected namespaces.
- Switch a policy between Enforce and Audit and read the effect in a PolicyReport.
- Write a mutate rule that adds a default label or `securityContext` field to matching pods.
- Write a generate rule that creates a default-deny NetworkPolicy in every new namespace.
- Read a Kyverno admission rejection and name the policy and rule that blocked it.
- Explain why a PolicyException has no effect on a default Kyverno 1.19.1 installation, and which controller flag turns exceptions on.

## Before you start

You need Kubernetes basics: pods, Deployments, ReplicaSets, namespaces, labels, resource requests and limits, and the commands `kubectl get`, `kubectl apply` and `kubectl describe`. It helps to know what an admission controller is: code in the API server that checks, and may change or reject, an object after authentication and authorization and before the object is stored.

Your playground is a single-node `kind` cluster running Kubernetes 1.35 with **Kyverno 1.19.1** installed from its release manifest, its webhooks ready. The Starfleet workloads run in `starfleet` and `outpost`. On purpose, `probe` has no resource limits at all, `scout` and `shuttle` set only a memory limit, and `scout` has no `team` label. No ClusterPolicy exists yet. `kubectl` already points at the playground cluster.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
