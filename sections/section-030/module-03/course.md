# Write ValidatingAdmissionPolicies With CEL

Kyverno and Gatekeeper are admission webhooks: the API server sends each request over HTTPS to a separate program and waits for its answer. Kubernetes also has a built-in way to check objects with no webhook at all. A **ValidatingAdmissionPolicy** is a Kubernetes resource that holds rules written in the Common Expression Language (CEL), and the API server evaluates those rules itself, inside its own process.

Keep one sentence in mind for this module: **the policy says what to check, and the binding says where to check it and what to do when the check fails.** You will limit Deployment replicas in production namespaces, read the limit from a ConfigMap, switch the binding between `Deny`, `Warn` and `Audit`, and decide when a CEL policy is the right tool and when Kyverno or Gatekeeper fits better.

The module has three parts. **Policies And CEL Expressions** writes a replica limit, binds it, and uses `object`, `oldObject`, `request` and `messageExpression` to make the rule precise. **Bindings, Params And Validation Actions** moves the limit into a ConfigMap and changes what happens on failure. **Choosing The Right Tool** writes a second policy, reads the two kinds of CEL errors, and compares the built-in policy with the two policy engines.

## Learning objectives

After this module you can:

- Write a ValidatingAdmissionPolicy with a CEL expression that limits Deployment replicas.
- Bind it to selected namespaces with a ValidatingAdmissionPolicyBinding and choose `Deny`, `Warn` or `Audit`.
- Pass a limit through a params resource instead of hard-coding it.
- Choose between ValidatingAdmissionPolicy, Kyverno and Gatekeeper for a given rule and say why.

## Before you start

You need Kubernetes basics: Deployments, namespaces, labels, ConfigMaps, the commands `kubectl apply`, `kubectl scale` and `kubectl patch`, and what an admission controller does. An admission controller is code in the API server that checks, and may reject, an object after authentication and authorization and before the object is stored.

Your playground is a single-node `kind` cluster running Kubernetes 1.35 with **no policy engine installed**: the API server does all the work. The `starfleet` namespace has the label `environment: production` and runs `scout`, `probe` and `shuttle`. On purpose, `scout` runs 8 replicas, so a replica limit has something to reject. The `outpost` namespace has the label `environment: sandbox` and runs `drifter`. A ConfigMap named `replica-limits` in `starfleet` holds `maxReplicas: "5"`. No ValidatingAdmissionPolicy exists yet.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
