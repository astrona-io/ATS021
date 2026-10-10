# Summary

A ValidatingAdmissionPolicy checks objects inside the API server with Common Expression Language (CEL) expressions, so it needs no webhook and no extra software. The policy holds `matchConstraints`, which say which requests it may see, and `validations`, which are expressions that must return `true`. A policy checks nothing until a ValidatingAdmissionPolicyBinding names it and selects namespaces or objects.

CEL expressions read `object` (the new object), `oldObject` (the stored object, `null` on a CREATE), `request` (the operation and the user) and `params`. A `messageExpression` builds an error message from real values. Changes to replicas also arrive through the `deployments/scale` subresource, which `kubectl scale` uses, so a replica rule must match it too.

The binding decides where and how a policy works. `matchResources` selects namespaces by label, `paramRef` picks the params object that `paramKind` declares, and `parameterNotFoundAction` decides what happens when that object is missing. `validationActions` turns a failed check into a rejection (`Deny`), a warning to the client (`Warn`) or an annotation in the audit event (`Audit`); `Deny` and `Warn` cannot be combined.

CEL mistakes show up at two moments. A syntax error makes the API server reject the policy itself. A type error, such as a wrong field name, is stored and reported in `status.typeChecking`. Reading a missing key at runtime is an error, not `false`, so `has()` must guard optional fields; with `failurePolicy: Fail` that error rejects the request.

The built-in policy fits short rules on the fields of one object. Kyverno fits when a team also needs mutation, generated objects or reports on existing objects. Gatekeeper fits teams that write Rego and want audit results for what already runs.

<!-- astrona:playground:destroy -->
