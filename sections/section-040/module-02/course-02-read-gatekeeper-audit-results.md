# Read Gatekeeper Audit Results

Kyverno writes its results to separate report objects. Gatekeeper keeps its results somewhere else: on the Constraint that holds the rule. An auditor who asks which objects break the `owner` label rule must read that Constraint. This part reads the violations, changes the cluster, and watches the results change on Gatekeeper's own schedule.

A **Constraint** is an object of a kind that a `ConstraintTemplate` created. It applies the Rego rule from the template to the objects it matches. The Constraint `deployments-need-owner` is of kind `K8sRequiredLabels`. It requires the label `owner` on Deployments in `starfleet` and `outpost`. Its enforcement action is `dryrun`: Gatekeeper reports a violation but never rejects the request.

<!-- astrona:playground:renew -->

List the Constraint:

```sh
kubectl get k8srequiredlabels
```

You should see something like:

```text
NAME                     ENFORCEMENT-ACTION   TOTAL-VIOLATIONS
deployments-need-owner   dryrun               2
```

The `TOTAL-VIOLATIONS` column comes from `status.totalViolations`. If the column is empty, the audit controller has not run yet; try again after a minute.

## Name the violating objects

The count is not evidence until you can name the objects. The `status` of the Constraint holds the time of the last audit and the list of violations:

```sh
kubectl get k8srequiredlabels deployments-need-owner -o jsonpath='{.status.totalViolations}{"\n"}{.status.auditTimestamp}{"\n"}{.status.violations}{"\n"}'
```

You should see something like:

```text
2
2026-11-02T19:00:54Z
[{"enforcementAction":"dryrun","group":"apps","kind":"Deployment","message":"missing required label: owner","name":"probe","namespace":"starfleet","version":"v1"},{"enforcementAction":"dryrun","group":"apps","kind":"Deployment","message":"missing required label: owner","name":"legacy-beacon","namespace":"starfleet","version":"v1"}]
```

Each entry in `status.violations` has the kind, the namespace, the name, the enforcement action and the message from the Rego rule. The audit found `probe` and `legacy-beacon`, the same two Deployments that the Kyverno reports flagged for other rules. `scout`, `shuttle` and `drifter` carry the `owner` label, so they do not appear. The `auditTimestamp` says when Gatekeeper wrote this list, which matters as evidence: it is the age of the answer.

## Why the audit finds old objects

Both Deployments existed before the Constraint did, so admission never checked them against it. The Gatekeeper **audit** controller (the `gatekeeper-audit` Deployment in `gatekeeper-system`) lists the existing objects that a Constraint matches and checks each one. Admission only sees a request at the moment it arrives. The audit controller sees what is already stored, so it finds objects that were created before the policy, objects created while the webhook was down, and objects that a `dryrun` or `warn` action let through.

The audit controller repeats on an interval. You can read the interval from the arguments of its container:

```sh
kubectl -n gatekeeper-system get deploy gatekeeper-audit -o jsonpath='{.spec.template.spec.containers[0].args}{"\n"}'
```

You should see something like:

```text
["--operation=audit","--operation=status","--operation=mutation-status","--operation=generate","--logtostderr","--disable-opa-builtin={http.send}","--disable-cert-rotation"]
```

No `--audit-interval` flag is set, so Gatekeeper uses its default of 60 seconds. The audit timestamps in this playground come one minute apart. The audit controller also stores at most 20 violations per Constraint by default (the `--constraint-violations-limit` flag). `totalViolations` keeps the full count, but the `violations` list stops at the limit. A report with 20 entries and a larger total is therefore incomplete.

## Watch the results change

To see the audit work on an object that admission accepted, fix one violation and create another. First give `probe` the `owner` label. Then create a Deployment named `relay` without the label:

```sh
kubectl -n starfleet label deploy/probe owner=team-starfleet
kubectl -n starfleet create deploy relay --image=ghcr.io/stefanprodan/podinfo:6.15.0
```

You should see something like:

```text
deployment.apps/probe labeled
deployment.apps/relay created
```

The API server accepted `relay`. The Constraint has `dryrun` enforcement, so Gatekeeper's admission webhook did not reject it. The next audit run sees it. Run the status command again until the list changes. It can take up to a minute:

```sh
kubectl get k8srequiredlabels deployments-need-owner -o jsonpath='{.status.auditTimestamp}{"\n"}{.status.violations}{"\n"}'
```

You should see something like:

```text
2026-11-02T19:01:54Z
[{"enforcementAction":"dryrun","group":"apps","kind":"Deployment","message":"missing required label: owner","name":"relay","namespace":"starfleet","version":"v1"}]
```

The list now holds `relay` and `legacy-beacon`. `probe` is gone because it has the label now. Nothing in the cluster rejected `relay`, and no request told Gatekeeper about it. The audit controller found it by listing the stored Deployments.

You now can read the Gatekeeper evidence: the count, the named objects, and the time of the audit. You also know its limits. The list is only as new as the last audit run, and it stops at the violations limit. Kyverno and Gatekeeper both report what breaks a rule, but neither one tells you who created `relay`. That question needs the third source, the API server audit log.

## Common pitfalls

> [!WARNING]
> - **Reading the list right after a change.** The list shows the last audit run, up to a minute old. Check `status.auditTimestamp` before you trust the answer.
> - **Trusting `totalViolations` and the list as equal.** The list stops at the violations limit (20 by default). The count does not.
> - **Expecting `dryrun` to reject.** `dryrun` records violations and admits the request. `deny` rejects it, and `warn` admits it with a warning to the user.
> - **Looking for violations on the template.** The `ConstraintTemplate` only defines the rule and the new kind. The results live on each Constraint of that kind.
> - **Worrying about `K8sNativeValidation engine is missing`.** The Constraint's `status.byPod` can show this message for the `vap.k8s.io` enforcement point. It means this Gatekeeper install has no engine for that enforcement point. The audit results above do not depend on it.
