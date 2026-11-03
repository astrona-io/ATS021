# Read Kyverno Policy Reports

An auditor does not want to hear that a policy exists. The auditor wants to know which workloads break it right now. Kyverno answers with **policy reports**: Kubernetes objects that list, for each checked resource, which policy rules passed and which failed. This part reads those reports for the `starfleet` namespace.

A **ClusterPolicy** is a Kyverno resource with rules that match objects and check them. Each rule here has `failureAction: Audit`, which means a failure is recorded but the request is not blocked. Start by listing the two policies the playground applied.

<!-- astrona:playground:renew -->

```sh
kubectl get clusterpolicy
```

You should see something like:

```text
Warning: kyverno.io/v1 ClusterPolicy is deprecated and will be removed in a future release; migrate to ValidatingPolicy, MutatingPolicy, GeneratingPolicy or ImageValidatingPolicy (policies.kyverno.io), see https://kyverno.io/docs/guides/migration-to-cel/
NAME                  ADMISSION   BACKGROUND   READY   AGE   MESSAGE
disallow-latest-tag   true        true         True    57s   Ready
require-limits        true        true         True    57s   Ready
```

The warning is part of Kyverno 1.19.1. It does not change how the policies work. The `BACKGROUND` column is the important one: `true` means Kyverno also checks objects that already exist. A **background scan** is a check that the Kyverno reports controller runs on existing resources, without any new request to the API server. It writes the result to a policy report.

## Where the results are

Kyverno writes one `PolicyReport` per checked resource in the namespace of that resource. A `PolicyReport` is an object of the API group `wgpolicyk8s.io`, a shared format for policy results. Resources that have no namespace get a `ClusterPolicyReport`. List the namespaced reports in all namespaces:

```sh
kubectl get policyreport -A
```

You should see something like:

```text
NAMESPACE   NAME                                   KIND         NAME                             PASS   FAIL   WARN   ERROR   SKIP   AGE
outpost     5e01add8-9e5a-498d-b749-a0b19e78de47   ReplicaSet   drifter-75bf78b48b               2      0      0      0       0      1s
outpost     a51c1c93-bf74-452f-b1af-baaf63b67c00   Deployment   drifter                          2      0      0      0       0      1s
outpost     f14c1ff8-a24c-4f98-9693-efc57c18fcdf   Pod          drifter-75bf78b48b-jh7hr         2      0      0      0       0      2s
starfleet   0454122c-dc07-4caf-899a-c66e977444d4   Pod          shuttle-66f447df44-kts6p         2      0      0      0       0      1s
starfleet   1a77c639-8112-4ebe-9364-209eb2f7a297   Deployment   probe                            1      1      0      0       0      1s
starfleet   614ced5d-952b-4701-8ba2-35500ef199c1   ReplicaSet   probe-675d7fd49d                 1      1      0      0       0      2s
starfleet   61a2e211-fa42-4342-9e2c-4802db88b615   ReplicaSet   shuttle-66f447df44               2      0      0      0       0      2s
starfleet   6910d48a-9bf7-46dc-99b2-310a0280e077   Deployment   legacy-beacon                    1      1      0      0       0      1s
starfleet   75c9bc2f-921b-4744-b86c-05bf36c8fc7e   Pod          probe-675d7fd49d-7lrs5           1      1      0      0       0      2s
starfleet   7c6dac2f-cb52-4ab2-bb8d-90f9468c0d0f   ReplicaSet   scout-69cc848f47                 2      0      0      0       0      2s
starfleet   8adea226-b2b0-4419-a9a1-2e39a1b0aa0f   Pod          scout-69cc848f47-9crpp           2      0      0      0       0      2s
starfleet   9ba53504-b30f-4dbd-908e-1c9cc35a5eb4   Deployment   scout                            2      0      0      0       0      2s
starfleet   aab936b3-57aa-4b6b-b6ae-b5664bf3331e   ReplicaSet   legacy-beacon-78f54b5c7b         1      1      0      0       0      1s
starfleet   e9e7b1bb-f05a-48a1-892a-56fb9d27b4b5   Pod          legacy-beacon-78f54b5c7b-7v92b   1      1      0      0       0      2s
starfleet   f62cad3a-ba40-4fcf-a5d6-799c52761570   Deployment   shuttle                          2      0      0      0       0      1s
```

The names and ages differ in your cluster. If the list is empty, the reports controller has not finished its first scan; run the command again after a short wait. The report name is the UID of the resource it describes. The `PASS` and `FAIL` columns are the `summary` counts. Two rules ran for each object, so a clean workload shows `2` passes, and `probe` and `legacy-beacon` each show `1` pass and `1` fail.

The policies match `Pod`, but reports also exist for Deployments and ReplicaSets. Kyverno **autogen** creates matching rules for the pod controllers (Deployment, ReplicaSet and others) from a rule written for pods. The generated rules have the prefix `autogen-` in their names. One failing Deployment therefore appears three times: as the Deployment, as its ReplicaSet and as its pod.

## Turn the reports into a list

The summary tells you that something fails, not what. Custom columns pick fields from each report. The `scope` field names the resource and the `summary` field holds the counts:

```sh
kubectl get policyreport -n starfleet -o custom-columns='KIND:.scope.kind,NAME:.scope.name,PASS:.summary.pass,FAIL:.summary.fail'
```

You should see something like:

```text
KIND         NAME                             PASS   FAIL
Pod          shuttle-66f447df44-kts6p         2      0
Deployment   probe                            1      1
ReplicaSet   probe-675d7fd49d                 1      1
ReplicaSet   shuttle-66f447df44               2      0
Deployment   legacy-beacon                    1      1
Pod          probe-675d7fd49d-7lrs5           1      1
ReplicaSet   scout-69cc848f47                 2      0
Pod          scout-69cc848f47-9crpp           2      0
Deployment   scout                            2      0
ReplicaSet   legacy-beacon-78f54b5c7b         1      1
Pod          legacy-beacon-78f54b5c7b-7v92b   1      1
Deployment   shuttle                          2      0
```

Custom columns cannot reach into the `results` list, which holds one entry per rule. `jq` can. The next command prints one line for each failed result in all namespaces, with the resource, the policy and the rule:

```sh
kubectl get policyreport -A -o json | jq -r '.items[] | .scope as $s | .results[]? | select(.result=="fail") | [$s.kind,$s.namespace,$s.name,.policy,.rule,.result] | @tsv'
```

You should see something like:

```text
Deployment	starfleet	probe	require-limits	autogen-require-cpu-memory-limits	fail
ReplicaSet	starfleet	probe-675d7fd49d	require-limits	autogen-require-cpu-memory-limits	fail
Deployment	starfleet	legacy-beacon	disallow-latest-tag	autogen-require-image-tag-not-latest	fail
Pod	starfleet	probe-675d7fd49d-7lrs5	require-limits	require-cpu-memory-limits	fail
ReplicaSet	starfleet	legacy-beacon-78f54b5c7b	disallow-latest-tag	autogen-require-image-tag-not-latest	fail
Pod	starfleet	legacy-beacon-78f54b5c7b-7v92b	disallow-latest-tag	require-image-tag-not-latest	fail
```

This is the answer to the auditor's first question. `probe` breaks `require-limits`, and `legacy-beacon` breaks `disallow-latest-tag`. Only those two workloads fail, and the `scout`, `shuttle` and `drifter` workloads pass both rules.

## One report in full

A summary is not enough evidence on its own. Each entry in `results` also holds the message, the time and how Kyverno produced the result. The report name is the UID of the Deployment, so you can look it up by name:

```sh
kubectl -n starfleet get policyreport "$(kubectl -n starfleet get deploy probe -o jsonpath='{.metadata.uid}')" -o yaml
```

You should see something like:

```text
apiVersion: wgpolicyk8s.io/v1alpha2
kind: PolicyReport
metadata:
  creationTimestamp: "2026-11-02T19:01:00Z"
  generation: 1
  labels:
    app.kubernetes.io/managed-by: kyverno
  name: 1a77c639-8112-4ebe-9364-209eb2f7a297
  namespace: starfleet
  ownerReferences:
  - apiVersion: apps/v1
    kind: Deployment
    name: probe
    uid: 1a77c639-8112-4ebe-9364-209eb2f7a297
  resourceVersion: "1543"
  uid: c486bac7-ba0c-483f-885e-fb55ee80ea5e
results:
- message: validation rule 'autogen-require-image-tag-not-latest' passed.
  policy: disallow-latest-tag
  properties:
    process: background scan
  result: pass
  rule: autogen-require-image-tag-not-latest
  scored: true
  source: kyverno
  timestamp:
    nanos: 0
    seconds: 1793645952
- message: 'validation error: Every container must set resources.limits.cpu and resources.limits.memory.
    rule autogen-require-cpu-memory-limits failed at path /spec/template/spec/containers/0/resources/limits/'
  policy: require-limits
  properties:
    process: background scan
  result: fail
  rule: autogen-require-cpu-memory-limits
  scored: true
  source: kyverno
  timestamp:
    nanos: 0
    seconds: 1793645952
scope:
  apiVersion: apps/v1
  kind: Deployment
  name: probe
  namespace: starfleet
  uid: 1a77c639-8112-4ebe-9364-209eb2f7a297
summary:
  error: 0
  fail: 1
  pass: 1
  skip: 0
  warn: 0
```

The `message` is the text from the policy, followed by the path in the object that failed. The `properties.process` field says `background scan`: Kyverno checked an object that already existed. The `ownerReferences` entry ties the report to the `probe` Deployment, so Kubernetes deletes the report when the Deployment is deleted. The `timestamp` is a Unix time in seconds.

You now can name every workload that fails each Kyverno rule, with the rule, the message and the way Kyverno found it. Kyverno repeats the background scan on a schedule, and it also updates a report when a resource changes. The next question is the same for the other engine: Gatekeeper keeps its results in a different place, on the Constraint itself.

## Common pitfalls

> [!WARNING]
> - **Reading only the summary.** `FAIL 1` does not say which rule failed. Read `results` with `jq` or the full report.
> - **Counting failures once per resource.** Autogen reports the same problem for the Deployment, its ReplicaSet and its pod. Count Deployments, or filter on `scope.kind`, to avoid a count three times too high.
> - **Looking for the report by workload name.** The report name is the UID of the resource. Find it with the UID, or list the reports with custom columns.
> - **Expecting `Audit` mode to block.** `failureAction: Audit` records a failure and lets the request through. Enforcement is a different setting.
> - **Looking in the wrong kind.** Reports for namespaced resources are `PolicyReport`; reports for cluster-scoped resources are `ClusterPolicyReport`. `kubectl get clusterpolicyreport` shows `No resources found` here because no cluster-scoped resource matches the policies.
