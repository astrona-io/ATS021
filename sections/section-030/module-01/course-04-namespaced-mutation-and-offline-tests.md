# Default Pod Labels With A NamespacedMutatingPolicy

A Pod in `starfleet` needs a team label even when its manifest omits one.
A Pod is a Kubernetes object that runs one or more containers. A default
must also respect a person's later label change. This example adds
`team: unassigned` to a new Pod and keeps `team: navigation` after an update.

<!-- astrona:playground:renew -->

Save this as `namespacedmutatingpolicy-default-team.yaml`:

```yaml
apiVersion: policies.kyverno.io/v1
kind: NamespacedMutatingPolicy
metadata:
  name: default-team
  namespace: starfleet
spec:
  evaluation:
    admission:
      enabled: true
    mutateExisting:
      enabled: false
  reinvocationPolicy: IfNeeded
  matchConstraints:
    resourceRules:
      - apiGroups: [""]
        apiVersions: ["v1"]
        resources: ["pods"]
        operations: ["CREATE", "UPDATE"]
  mutations:
    - patchType: JSONPatch
      jsonPatch:
        expression: |
          !has(object.metadata.labels) ?
            [JSONPatch{op: "add", path: "/metadata/labels", value: {"team": "unassigned"}}] :
          !("team" in object.metadata.labels) ?
            [JSONPatch{op: "add", path: "/metadata/labels/team", value: "unassigned"}] :
            []

```

Apply it:

```sh
kubectl apply -f namespacedmutatingpolicy-default-team.yaml
```

A `NamespacedMutatingPolicy` is a Kyverno resource that changes matching
objects only in the namespace where the policy exists. Kyverno 1.19.1 serves
it as `policies.kyverno.io/v1`. The cluster-scoped kind in this family is
`MutatingPolicy`; it can select resources across namespaces. Both use the
same mutation fields. This example keeps the course's pinned version.

The Kyverno admission controller evaluates this policy when the application
programming interface (API) server receives a matching request.
`matchConstraints.resourceRules` selects core `v1` Pods on `CREATE` and
`UPDATE`. `evaluation.admission.enabled` enables admission evaluation;
`mutateExisting.enabled: false` leaves background mutation disabled.
Existing Pods change only when a matching request updates them.

The patch uses Common Expression Language (CEL), a small expression language.
A JSON Patch is a list of operations that edit fields at named paths.
The first branch creates the labels map when it is absent. The second
branch adds one key to an existing map, preserving other labels. The final
`[]` returns no edits when the key already exists, even if its value is
empty. `reinvocationPolicy: IfNeeded` allows another evaluation during the
same admission request; checking for absence makes repeated evaluation safe.

## Prove CREATE and UPDATE

A label is a key and value in an object's metadata. The policy checks
`object`, the incoming Pod. Checking only `oldObject`, the previously stored
Pod, would miss the value a person is submitting now. A patch with
`op: add` alone is insufficient: JSON Patch can replace an existing map key.
The condition is what makes this a default.

Remove the earlier label-defaulting ClusterPolicy so it cannot supply the
same label during this demonstration. Then inspect the new policy:

```sh
kubectl delete clusterpolicy add-team-label --ignore-not-found
kubectl get namespacedmutatingpolicy default-team -n starfleet -o yaml
kyverno version
```

Check that the namespace is `starfleet`, both operations are present and
the CLI reports 1.19.1. The command-line interface (CLI) runs on your terminal;
the admission controller runs in the cluster. Allow a few seconds for
Kyverno to register the policy before creating the Pods.

Save this as `pods-team.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: scout-default
  namespace: starfleet
spec:
  serviceAccountName: scout
  containers:
  - name: scout
    image: ghcr.io/stefanprodan/podinfo:6.15.0
    resources:
      limits:
        cpu: 100m
        memory: 64Mi
---
apiVersion: v1
kind: Pod
metadata:
  name: scout-owned
  namespace: starfleet
  labels:
    team: navigation
spec:
  serviceAccountName: scout
  containers:
  - name: scout
    image: ghcr.io/stefanprodan/podinfo:6.15.0
    resources:
      limits:
        cpu: 100m
        memory: 64Mi

```

The first Pod omits labels entirely. The second supplies a team value.
Both use the existing `scout` service account, the identity a Pod uses for
API requests, and set resource limits so a limits policy can accept them.

Apply it:

```sh
kubectl apply -f pods-team.yaml
```

Then check the result and send two updates:

```sh
kubectl get pods scout-default scout-owned -n starfleet -L team
kubectl label pod scout-default -n starfleet team=navigation --overwrite
kubectl annotate pod scout-default -n starfleet proof=retained --overwrite
kubectl get pod scout-default -n starfleet -o yaml
```

Look for `unassigned` on the first Pod and `navigation` on the second before
the updates. After the label change and the annotation update, the first
Pod must still have `team: navigation`. An annotation stores metadata that
is not used for object selection; changing it sends another UPDATE without
changing the label. If a Pod missed the default during registration, delete
these two Pods and apply their manifest again.

## Test local files without a cluster

The Kyverno CLI evaluates policy against saved resource files. With
`--resource` and no `--cluster`, `kyverno apply` uses those files without
installing the policy or contacting the API server:

```sh
kyverno apply namespacedmutatingpolicy-default-team.yaml --resource pods-team.yaml
```

Look for successful mutation results for both resources. This
checks the patch locally; it does not prove that cluster webhooks are ready.
The input file still omits the first label, regardless of your live updates.

A repeatable test also needs expected fields. Save this local test fixture
as `expected-pods.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: scout-default
  namespace: starfleet
  labels:
    team: unassigned
spec:
  serviceAccountName: scout
  containers:
  - name: scout
    image: ghcr.io/stefanprodan/podinfo:6.15.0
    resources:
      limits:
        cpu: 100m
        memory: 64Mi
---
apiVersion: v1
kind: Pod
metadata:
  name: scout-owned
  namespace: starfleet
  labels:
    team: navigation
spec:
  serviceAccountName: scout
  containers:
  - name: scout
    image: ghcr.io/stefanprodan/podinfo:6.15.0
    resources:
      limits:
        cpu: 100m
        memory: 64Mi

```

These are expected resources for comparison; do not apply them. Save the test
definition as `kyverno-test.yaml` in the same folder as the three YAML files:

```yaml
apiVersion: cli.kyverno.io/v1alpha1
kind: Test
metadata:
  name: default-team
policies:
  - namespacedmutatingpolicy-default-team.yaml
resources:
  - pods-team.yaml
results:
  - isMutatingPolicy: true
    policy: starfleet/default-team
    kind: Pod
    resources:
      - starfleet/scout-default
      - starfleet/scout-owned
    patchedResources: expected-pods.yaml
    result: pass

```

`policies` and `resources` name local input files. `results` identifies the
namespaced policy and Pods to compare; `isMutatingPolicy` selects this policy
family. `patchedResources` supplies the expected complete resources after mutation.
Run the test from that folder:

```sh
kyverno test . --require-tests
```

Look for both cases to pass. `--require-tests` makes a folder with no test
definitions fail instead of giving a false sense of coverage. These fixtures
exercise local CREATE evaluation; the live label and annotation changes
prove UPDATE admission separately.

For new mutation policies, use `MutatingPolicy` for cluster-wide selection
or `NamespacedMutatingPolicy` for one namespace. Keep `kyverno.io/v1`
ClusterPolicy when maintaining existing policies that use `match`,
`patchStrategicMerge`, anchors or generate rules. Kyverno 1.19.1 deprecates
that older family, but it remains useful to read and maintain. Migration
requires rewriting and testing the rule; changing only `apiVersion` and
`kind` does not translate its fields.

You can now write a namespaced default that handles missing maps, preserves
human changes and runs through both offline commands. Local tests establish
the patch's behavior; admission requests establish that the installed policy
has the intended effect.

## Common pitfalls

> [!WARNING]
> - **Using `kyverno.io/v1` for the new kind.** Use `policies.kyverno.io/v1` with `NamespacedMutatingPolicy` on Kyverno 1.19.1.
> - **Matching CREATE only.** A missing label on UPDATE also needs the default.
> - **Adding the label without checking the key.** An `add` patch can overwrite an existing value. Check `object` and preserve empty values too.
> - **Patching a missing parent map.** Create `/metadata/labels` when absent; otherwise add only `/metadata/labels/team`.
> - **Treating offline success as admission proof.** Also create and update live Pods, and check that other namespaces remain unchanged.

## Your mission: Default Pod Labels With A NamespacedMutatingPolicy

You can now test a namespaced mutation without overwriting a team value.
Write the policy, test it offline and prove it with new Pods and a later update.

```sh
astrona stop ats-021-playground-030-01
astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-030/module-01/labs/lab-02
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-030/module-01/labs/lab-02
```

When you finish, remove the lab and resume the playground:

```sh
astrona destroy ats-021-lab-030-01-02
astrona start ats-021-playground-030-01
```
