# Audit Status And Template Errors

Admission only sees new create, update and delete requests. Gatekeeper also has an audit controller. The audit controller lists existing objects, evaluates constraints against them, and writes the result into each constraint's status.

## Audit results

The `probe` pod already existed before you created the constraint, so admission did not check its original create request. Audit finds it later because it matches the constraint and has no `team` label.

<!-- astrona:playground:renew -->

Read the constraint status:

```sh
kubectl get k8srequiredlabels require-team-label -o jsonpath='{.status.totalViolations}{" total violations\n"}{range .status.violations[*]}{.kind}{" "}{.namespace}{"/"}{.name}{": "}{.message}{"\n"}{end}'
```

After audit runs, you should see output like this:

```text
1 total violations
Pod starfleet/probe-6f569ff97-qbm22: missing required label: team
```

The pod name in your cluster will have a different suffix. The useful fields are `status.totalViolations` and `status.violations`. Each violation names the kind, namespace, object name and message.

If you left the `dryrun` and `warn` pods from the previous page in place, the same command later reports them too:

```text
3 total violations
Pod starfleet/warned: missing required label: team
Pod starfleet/probe-6f569ff97-qbm22: missing required label: team
Pod starfleet/no-team: missing required label: team
```

That output shows the difference between admission and audit. Admission handles the request in front of it. Audit reports the current state of the cluster.

## Template errors

Gatekeeper also records template problems in status. The playground includes a broken ConstraintTemplate named `k8sbrokenlabels`. Its Rego rule is missing a closing brace.

Check its status:

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

You now know the full Gatekeeper loop: a template defines the kind and Rego code, a constraint selects objects and passes parameters, admission enforces new requests, and audit reports existing violations.

## Common pitfalls

> [!WARNING]
> - **Expecting audit status immediately.** The audit controller runs on its own interval, so `totalViolations` can lag behind admission.
> - **Forgetting that audit reports live objects.** If you delete a violating pod, the next audit run removes it from the status.
> - **Stopping at `kubectl apply` for a template.** A broken template can be stored but still have `status.created: false`.
> - **Reading only the first line of a Rego error.** The pointer line often shows the exact missing brace, unsafe variable or parse location.

## Your mission: Enforce Constraints With Gatekeeper And Rego Lab

You can now read the status of a `ConstraintTemplate`, fix a Rego error, and use a Constraint with `deny` and `dryrun` enforcement actions. The mission starts a cluster with Gatekeeper and a broken template, and asks you to fix the template, refuse the `latest` tag in `starfleet` and list the `drifter` pod in the audit results of a second constraint for `outpost`.

Pause the playground first, so the lab has the memory it needs:

```sh
astrona stop ats-021-playground-030-02
```

Start the lab, then grade it when you are done:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-030/module-02/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-030/module-02/labs/lab-01
```

When you are done, remove the lab and start the playground again:

```sh
astrona destroy ats-021-lab-030-02
astrona start ats-021-playground-030-02
```
