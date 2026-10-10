# Overview: Enforce Constraints With Gatekeeper And Rego (Playground)

This is a **playground**, not a lab. It starts a fresh cluster with Gatekeeper
and the example workloads, and then waits. There is no task, no
`astrona submit` and no pass or fail. Write templates and constraints, change
their enforcement actions, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` cluster running Kubernetes 1.35. `kubectl` is already
  pointed at it.
- **Gatekeeper 3.23.1** with the controller manager and audit controller ready.
  Gatekeeper is the admission controller. Open Policy Agent (OPA) evaluates the
  Rego policy code inside Gatekeeper.

  | Namespace | Workloads | Deliberate gaps |
  | --- | --- | --- |
  | `starfleet` | `scout`, `probe`, `shuttle` | `probe` has no `team` label |
  | `outpost` | `drifter` | `drifter` uses the image tag `latest` |

- One broken `ConstraintTemplate` named `k8sbrokenlabels`. Its Rego code does
  not compile, so Gatekeeper records the error in the template status.
- No working `ConstraintTemplate` and no `Constraint` yet.

## Helpers

Paste these once in each new terminal. `constraint_status` shows whether a
constraint has audit violations. `template_error` prints the first error stored
on the broken template.

```sh
constraint_status() {
  kubectl get "$1" "$2" -o jsonpath='{.status.totalViolations}{" total violations\n"}{range .status.violations[*]}{.namespace}{"/"}{.name}{": "}{.message}{"\n"}{end}'
}
template_error() {
  kubectl get constrainttemplate k8sbrokenlabels -o jsonpath='{.status.byPod[0].errors[0].message}{"\n"}'
}
```

Use them like this: `constraint_status k8srequiredlabels require-team-label`
and `template_error`.

## Practice tasks

- Write a constraint that requires the label `team` on every Pod in
  `starfleet`, then wait for audit to report `probe`.
- Change the same constraint from `deny` to `dryrun`, then create a pod that
  breaks the rule and compare admission with audit.
- Add `outpost` to the match and change the parameter from `team` to `app`.
  Predict which objects violate the constraint before you check the status.
- Write a separate template that blocks images tagged `latest`, and prove that
  `drifter` is reported by audit.
- Fix the prepared broken template in a copy and check that its status no
  longer has a compile error.
