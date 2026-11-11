# Compare Policy Selection, Evaluation And Admission Results

A policy engine can be healthy while a policy matches the wrong objects or evaluates the wrong field. Separate selection from evaluation before changing enforcement.

For Kyverno, inspect the matched kinds, namespaces, exclusions and rule type. Validation decides whether a request is accepted. Mutation changes the admitted object. Generation creates a separate object through a controller. Each operation needs evidence appropriate to its behavior.

For Gatekeeper, a ConstraintTemplate defines the policy code and parameter schema; a constraint supplies scope and parameter values. Check that the template created its constraint kind before interpreting the constraint’s result. Audit status reports existing violations on a controller interval, while admission evaluates the current request.

For a ValidatingAdmissionPolicy, follow the binding to the policy, its parameter object and validation actions. A correct expression cannot protect an object that the binding never matches.

Test an allowed object, a forbidden object and an object outside the intended scope. Keep the webhook or admission mechanism enabled. Broad exclusions or a reporting-only action can make a rejection disappear while removing the protection the exercise requires.
