# Summary

Gatekeeper turns Rego policy into Kubernetes admission control through two resources. A ConstraintTemplate defines a new constraint kind, declares any parameters with an OpenAPI schema, and holds the Rego rule that returns violations. Gatekeeper creates a CustomResourceDefinition from the template when the Rego compiles.

A Constraint is the instance that applies the template to real Kubernetes objects. Its `match` block selects the API groups, kinds and namespaces, and its `parameters` block becomes `input.parameters` in Rego. Its `enforcementAction` decides whether Gatekeeper blocks the request, records it only, or returns a warning while allowing it.

Admission and audit answer different questions. Admission decides the request being made now. Audit scans objects that already exist and writes violations into the constraint status. A useful Gatekeeper check reads both the admission error and the status fields, because each one explains a different part of the system.

Template status is part of the troubleshooting path. If a template has invalid Rego, Gatekeeper stores the template but marks `status.created` as `false` and records the parse or compile error under `status.byPod`.

<!-- astrona:playground:destroy -->
