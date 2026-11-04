# Solution Walkthrough

Write a NamespacedMutatingPolicy, a Kyverno resource that changes objects
only in its own namespace. Test its patch locally, then prove admission on
Pods in `starfleet` from the terminal.

| Goal | Field or command |
| --- | --- |
| One namespace | `kind: NamespacedMutatingPolicy` and `metadata.namespace` |
| Both request types | `matchConstraints.resourceRules[].operations` |
| Keep a person's value | Check `object.metadata.labels` before adding a patch |
| Offline comparison | `kyverno apply` and `kyverno test` |

## The feedback loop

Run grading from the host terminal where you started the lab:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-030/module-01/labs/lab-02
```

Before you write the policy, expect `policy-offline`, `admission-default`
and `student-pods` to fail. Run the same command after each step.
These are expected states, not captured command output.

## Step 1: Test and install the policy

The command-line interface (CLI) evaluates local files without calling the
cluster when you supply resource files and omit `--cluster`. The prepared
folder contains input Pods, expected patched Pods and a `kyverno-test.yaml`
test definition. Save this as `/tmp/kyverno-team-test/policy.yaml`:

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

`apiVersion` and `kind` select the newer policy resource. `metadata` names
it and sets its namespace. `evaluation` enables admission and disables
mutation of existing resources. `reinvocationPolicy: IfNeeded` permits
another evaluation if admission changes the object again.

`matchConstraints.resourceRules` selects the core application programming
interface (API) group, version `v1`, resource `pods`, and both operations.
`mutations` contains a JSON Patch, an ordered list of field edits, built
with Common Expression Language (CEL). The first branch creates the labels
map if absent; the second adds only `team` to an existing map. The last
branch returns an empty patch list when `team` already exists.

Run the two offline commands:

```sh
kyverno apply /tmp/kyverno-team-test/policy.yaml --resource /tmp/kyverno-team-test/pods.yaml
kyverno test /tmp/kyverno-team-test --require-tests
```

Look for all four test cases to pass. The `patchedResources` entries compare
expected field values, so a policy that overwrites `navigation` fails.
An empty value counts as an existing label and must also remain unchanged.

Apply it:

```sh
kubectl apply -f /tmp/kyverno-team-test/policy.yaml
```

Then check the result:

```sh
kubectl get namespacedmutatingpolicy default-team -n starfleet -o yaml
```

Check the stored specification and policy status. Registration can take a
few seconds. Run the check: `policy-offline` and `admission-default` should
now pass. The latter sends real CREATE and UPDATE requests, including a
label removal, and checks that `outpost` is unaffected. `student-pods`
still needs your demonstration.

## Step 2: Create the demonstration Pods

Save this as `pod-scout-default.yaml`:

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

```

`metadata` names the Pod and its namespace. `serviceAccountName` selects its
identity; `containers` sets its image and resource limits.

Apply it:

```sh
kubectl apply -f pod-scout-default.yaml
```

Save this as `pod-scout-labelled.yaml`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: scout-labelled
  namespace: starfleet
  labels:
    app: scout
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

The extra `metadata.labels.app` field tests that the patch keeps unrelated
labels in the same map.

Apply it:

```sh
kubectl apply -f pod-scout-labelled.yaml
```

Then check the result:

```sh
kubectl get pods scout-default scout-labelled -n starfleet -L team,app
kubectl label pod scout-default -n starfleet team=navigation --overwrite
kubectl annotate pod scout-default -n starfleet proof=retained --overwrite
kubectl get pod scout-default -n starfleet -o yaml
```

First look for `unassigned` on both Pods and `app: scout` on `scout-labelled`.
After the label change and annotation update, look for `team: navigation`
and `proof: retained` on `scout-default`. Kyverno reads the submitted
`object`, so it sees the person's value and returns no patch.

Run the check: `student-pods` should now pass, along with the other checks.

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-030/module-01/labs/lab-02
```

## If a check stays red

- **`policy-offline`:** keep the saved policy and live specification in
  agreement. Use the installed CLI 1.19.1 and preserve existing and empty
  team values in the supplied tests.
- **`admission-default`:** match both CREATE and UPDATE. Check for the label
  on `object`, the incoming object, and handle a missing labels map.
  Return no patch when `team` exists. Allow time for policy registration.
- **`student-pods`:** use the exact Pod names, change `scout-default` to
  `navigation`, and annotate it after the label change. If you created Pods
  before admission was active, delete those two Pods and create them again.
