# Question

Solve this question on: `terminal`

## Scenario

The `starfleet` team wants new Pods to carry a team label. A Pod is the
Kubernetes object that runs one or more containers. Kyverno 1.19.1 and its
command-line interface (CLI) are installed, and the `scout` service account
exists in `starfleet` and `outpost`. No policy or task Pod exists yet.
The default must preserve labels that a person sets later.

## Tasks

1. **Write a namespaced policy.** Save the policy at
   `/tmp/kyverno-team-test/policy.yaml`. Use
   `policies.kyverno.io/v1`, kind `NamespacedMutatingPolicy`, name
   `default-team`, namespace `starfleet`. Match core `v1` `pods` on both
   `CREATE` and `UPDATE`. Add `team: unassigned` only when the incoming
   Pod has no `team` label. Preserve every existing label, including an
   empty `team` value. Keep `outpost` outside the policy's scope.
   Use admission mutation; leave mutation of existing resources disabled.

2. **Test the policy offline.** Run `kyverno apply` against
   `/tmp/kyverno-team-test/pods.yaml`, then `kyverno test` against
   `/tmp/kyverno-team-test`. The supplied cases cover missing labels,
   an unrelated label, `team: navigation` and an empty `team` value.
   Apply the saved policy to the cluster with the same specification.

3. **Prove defaulting and retention.** Create two Pods in `starfleet`,
   named `scout-default` and `scout-labelled`, using service account
   `scout` and image `ghcr.io/stefanprodan/podinfo:6.15.0`.
   Submit both without `team`; give `scout-labelled` the label `app: scout`.
   Both must receive `team: unassigned`, and `app: scout` must remain.
   Change `scout-default` to `team: navigation`, then add annotation
   `proof: retained` to send another UPDATE. Leave that Pod with
   `team: navigation` and that annotation. Removing `team` in an UPDATE
   must add the default again.
