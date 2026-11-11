# Read Gatekeeper Audit Results

Gatekeeper admission evaluates incoming requests. Its audit controller also evaluates existing resources and records violations in constraint status. Read the object identities and the audit timestamp before using that status as an inventory.

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

If you left the `dryrun` and `warn` pods from the enforcement-action exercise in place, the same command later reports them too:

```text
3 total violations
Pod starfleet/warned: missing required label: team
Pod starfleet/probe-6f569ff97-qbm22: missing required label: team
Pod starfleet/no-team: missing required label: team
```

That output shows the difference between admission and audit. Admission handles the request in front of it. Audit reports the current state of the cluster.

A dryrun constraint lets requests proceed while the audit controller reports matching existing violations. Keep the original violating workload when the task is to inventory it.

## Common pitfalls

> [!WARNING]
> - Wait for a fresh audit timestamp before interpreting the current violation list.
> - Deleting a violating Pod removes evidence from a later audit result.
