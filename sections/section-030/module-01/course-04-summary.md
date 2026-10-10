# Summary

Kyverno is a policy engine that runs as a mutating and a validating admission webhook. Its rules select objects with `match` and `exclude`, then validate, mutate or generate.

## What you learned

A ClusterPolicy applies in every namespace and a Policy in one. A validate rule with a `pattern` describes a good object; `"?*"` means any non-empty value. A rejection names the webhook (`validate.kyverno.svc-fail`), the policy, the rule, the message and the path where the pattern failed. Autogen turns a pod rule into `autogen-<rule>` rules for the pod templates of Deployments, ReplicaSets, StatefulSets, DaemonSets, Jobs and CronJobs. Kyverno 1.19.1 marks `kyverno.io/v1` ClusterPolicy as deprecated in favour of CEL-based kinds in `policies.kyverno.io`, but it still works.

`failureAction: Enforce` refuses a failing request; `failureAction: Audit` allows it and records a `fail` result in a PolicyReport and a `PolicyViolation` event. The background scan checks existing objects and writes one PolicyReport per object in its namespace, so you can see who breaks a rule before you enforce it. Under Enforce, an existing workload that breaks the rule keeps running, but its new pods are refused.

A mutate rule with `patchStrategicMerge` changes objects on create and update; `+(field)` adds a field only when it is missing, and autogen also mutates workload templates. A generate rule creates an object when a matching object is created; `{{request.object.metadata.name}}` inserts the trigger's name, `synchronize: true` recreates a deleted generated object, and `generateExisting: true` is needed for objects that existed before. PolicyExceptions are switched off on a default 1.19.1 installation (`--enablePolicyException=false`). The key facts to remember are these:

- `match` selects, the action decides; read rejections for policy, rule and path.
- Introduce a rule in Audit, read the PolicyReports, then switch to Enforce.
- Use `+(field)` for defaults; mutate and generate act only on new requests unless told otherwise.
- Check that exceptions are enabled before you rely on a PolicyException.

<!-- astrona:playground:destroy -->
