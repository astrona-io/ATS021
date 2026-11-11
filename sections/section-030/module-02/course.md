# Enforce Constraints With Gatekeeper And Rego

Kyverno lets you write many platform rules as YAML patterns. Gatekeeper takes a different path: it uses Open Policy Agent, or OPA, to evaluate Rego policy code during admission. Rego is OPA's policy language. In Gatekeeper, you put that Rego code in a Kubernetes resource, and Gatekeeper calls OPA when the API server asks whether an object is allowed.

Keep one sentence in mind for this module: **a ConstraintTemplate defines a new constraint kind, and each Constraint configures where that rule applies.** You will create a template that requires labels, create a constraint from it, change the constraint between `deny`, `dryrun` and `warn`, and read both audit results and template compile errors.

The module has four parts. **ConstraintTemplates And Rego** creates a new constraint kind and explains the small Rego rule inside it. **Constraints And Enforcement Actions** applies that kind to pods in one namespace and proves the difference between `deny`, `dryrun` and `warn`. **Audit Status And Template Errors** reads the audit results for existing pods and finds the compile error in a broken template. **Constraints And Pods Created By Controllers** shows that a Constraint on Pods also refuses the pods a Deployment creates, and that the refusal appears in the events of the ReplicaSet, not in the output of `kubectl apply`.

**Repair The Chart That Generates A Rejected Pod** carries a policy correction into chart files and checks the installed release and its Pods.

## Learning objectives

After this module you can:

- Write a ConstraintTemplate with a Rego violation rule and the parameter schema for its constraint.
- Create a Constraint that applies the template to selected kinds and namespaces with parameters.
- Switch a Constraint between `deny`, `dryrun` and `warn` with `enforcementAction`.
- Read the audit results in a Constraint's status and list existing violations.
- Find the error in a ConstraintTemplate whose Rego does not compile from its status.
- Find the Gatekeeper refusal of a pod that a Deployment creates in the `FailedCreate` event of its ReplicaSet, and fix the pod template.
- Write one ConstraintTemplate with a rule on Pods and a rule on Deployments, and repair a Helm chart until its release passes the Constraint.

## Before you start

You need Kubernetes basics: pods, Deployments, ReplicaSets, namespaces, labels, custom resources, admission controllers, and the commands `kubectl get`, `kubectl apply` and `kubectl describe`. It helps to know that a CustomResourceDefinition creates a new Kubernetes resource kind. The second lab uses Helm, a tool that renders chart templates and installs the result as a release; the lab needs only `helm upgrade --install`, `helm list`, `helm history`, `helm lint` and `helm template`.

Your playground is a single-node `kind` cluster running Kubernetes 1.35 with **Gatekeeper 3.23.1** installed. Gatekeeper is the admission controller. OPA evaluates the Rego code inside Gatekeeper. The `starfleet` namespace has `scout`, `probe` and `shuttle`; `probe` has no `team` label on purpose. The `outpost` namespace has `drifter`, which uses the image tag `latest`. One broken ConstraintTemplate named `k8sbrokenlabels` already exists so you can read its status. No working ConstraintTemplate or Constraint exists yet.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
