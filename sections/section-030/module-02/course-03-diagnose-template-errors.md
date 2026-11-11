# Diagnose Gatekeeper Template Errors

A ConstraintTemplate can be accepted by the API server while Gatekeeper cannot compile its Rego policy. In that case, the constraint kind is unavailable. Inspect the template’s controller status before trying to repair a constraint or a workload. The playground includes the deliberately broken template used below.

## Template errors

Gatekeeper also records template problems in status. The playground includes a broken ConstraintTemplate named `k8sbrokenlabels`. Its Rego rule is missing a closing brace.

Check its status:

<!-- astrona:playground:renew -->

```sh
kubectl get constrainttemplate k8sbrokenlabels -o jsonpath='{.status.created}{"\n"}{.status.byPod[0].errors[0].message}{"\n"}'
```

You should see:

```text
false
Could not ingest Rego: invalid ConstraintTemplate: 1 error occurred: template:6: rego_parse_error: unexpected eof token
	  msg := "the team label is missing"
	                                   ^
```

`status.created` is `false`, so Gatekeeper did not create a usable constraint kind from this template. The error message points at the Rego line where parsing reached the end of the file. In this case, the parser expected the missing closing brace for the `violation` rule.

The exam task may give you a template that applies cleanly but never creates its constraint kind. Check the template status before you spend time debugging the constraint.

Once the template creates its constraint kind, verify the constraint with an allowed object and a denied object. Successful storage of the template alone does not prove its policy runs.

## Common pitfalls

> [!WARNING]
> - Check `status.created` and controller error messages, not only the apply result.
> - Read the pointer line in a Rego parse error to locate the missing syntax.
