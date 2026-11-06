# Summary

A platform can produce compliance evidence without extra tools. Kyverno writes policy reports, Gatekeeper writes violations to the status of each Constraint, and the Kubernetes API server writes audit events. Each source answers a different kind of question.

Kyverno policy reports list, per checked resource, which rules passed and which failed. A `PolicyReport` holds the policy, the rule, the result, the message and how Kyverno found the result. Autogen creates reports for Deployments and ReplicaSets from rules written for pods, so one problem appears once per level. The `summary` counts show that something fails, and the `results` list shows what.

Gatekeeper audit lists the stored objects that break a Constraint. The `status` holds `totalViolations`, the time of the last audit and a list of violating objects. The audit runs on an interval, 60 seconds by default, and the list stops at a limit, 20 by default. A `dryrun` Constraint reports violations and rejects nothing.

The two engines report objects that admission never saw. The background scan in Kyverno and the audit controller in Gatekeeper check what is already stored. They find objects created before the policy, objects admitted in `Audit` or `dryrun` mode, and objects admitted while a webhook was down. Their results describe the present state and change when the objects change.

The audit log records who did what and when. A `Metadata` event holds the verb, the user, the target, the time and the response code, but no request or response body. A refused request appears with its `403` code and the decision `forbid`. Filters must name a namespace and an object, because the cluster's own controllers create many events.

A complete answer often joins two sources. A policy report or Constraint status names the object that breaks a rule, and the audit log names the user who changed it. Evidence that must outlive the cluster has to be copied out, because reports are rewritten, Constraint lists are replaced on each audit run, and the log lives on the node.

Key facts:

- Kyverno: `PolicyReport` for namespaced resources, `ClusterPolicyReport` for cluster-scoped ones.
- Gatekeeper: results are in `status.violations` and `status.totalViolations` of each Constraint.
- Audit log: one JSON event per line, read with `jq`.

A software bill of materials (SBOM) supplies a fourth kind of evidence: the packages and versions detected in an image. Keep it tied to an image digest and platform. Cluster reports describe policy compliance, audit events describe API activity, and an SBOM describes detected software contents.

<!-- astrona:playground:destroy -->
