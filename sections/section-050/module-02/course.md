# Admit Only Trusted Images

A container image reference decides what code runs in the cluster. The reference `nginx:latest` can point at different content next week than it does today. A check in a delivery pipeline can stop a bad release early, but anyone with `kubectl` can still create a Deployment by hand. The last line of defence is the API server itself: an admission controller (code in the API server that checks an object before the cluster stores it) can reject a Deployment whose image reference breaks a rule.

Keep one sentence in mind for this module: **admission sees only the image reference, so the policy can only check the registry, the tag and the digest.** It cannot see what is inside the image. This module builds three rules on that text: images must come from one registry, images must not use the `latest` tag or no tag, and images in a production namespace must be pinned by digest. You write the rules with Kyverno and the registry rule again with Gatekeeper.

The module has four parts. **Read An Image Reference** explains the registry, the tag and the digest, and shows that a cluster without a policy admits every reference. **Allow Only One Registry With Kyverno** writes the first `ClusterPolicy`. **Reject Latest, Untagged And Unpinned Images** adds the tag rules and a digest rule for production only. **Allow Only One Registry With Gatekeeper** writes the same registry rule as a `ConstraintTemplate` and a Constraint and compares the two rejection messages.

## Learning objectives

After this module you can:

- Name the three parts of an image reference (registry, tag, digest) and say which of them can change what the image contains.
- Explain why a tag can point at different content over time and a digest cannot.
- Write a Kyverno `ClusterPolicy` that admits images only from an approved registry.
- Reject images with the `latest` tag or with no tag.
- Require images pinned by digest in a production namespace and leave other namespaces alone.
- Write the same registry rule as a Gatekeeper `ConstraintTemplate` and Constraint.
- Prove each policy with a server-side dry run: one object that the API server rejects and one that it accepts.
- Read a rejection message and tell which engine and which rule produced it.

## Before you start

You need `kubectl`, YAML and the idea of a Deployment. Basic knowledge of Kyverno and Gatekeeper helps, but each part defines the objects it uses.

Your playground is a single-node kind cluster running Kubernetes 1.35.8 with Kyverno 1.19.1 and Gatekeeper 3.23.1. Both admission webhooks are ready. The `starfleet` namespace has the label `environment: development` and runs the `scout` Deployment. The `starfleet-prod` namespace has the label `environment: production` and is empty. No image policy exists yet. The cluster has no registry of its own, and the module uses no image signing or scanning tools.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
