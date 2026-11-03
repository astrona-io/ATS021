# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. The output below comes from a real run of this lab. Long messages are shortened where the text says so.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-030/capstone/labs/lab-01
```

The start takes several minutes, because it installs Kyverno and Gatekeeper. Right after the start no check passes. The three rules are enforced by three different components: Kyverno (resource limits), Gatekeeper (the `latest` tag) and the API server itself (replicas).

## Step 1: Require limits with Kyverno, except for probe

A `validate` rule with `failureAction: Enforce` makes the Kyverno admission webhook refuse a pod that fails the pattern. The `preconditions` block skips the rule for pods whose `app` label is `probe`. The expression `request.object.metadata.labels.app || ''` returns an empty string when a pod has no `app` label, so such a pod is still checked. Kyverno also generates a rule for Deployments, so the same precondition applies there. Save this as `clusterpolicy-require-limits.yaml`:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-limits
spec:
  rules:
    - name: require-cpu-memory-limits
      match:
        any:
          - resources:
              kinds: ["Pod"]
              namespaces: ["starfleet"]
      preconditions:
        all:
          - key: "{{ request.object.metadata.labels.app || '' }}"
            operator: NotEquals
            value: probe
      validate:
        failureAction: Enforce
        message: "Every container in starfleet must set resources.limits.cpu and resources.limits.memory."
        pattern:
          spec:
            containers:
              - resources:
                  limits:
                    cpu: "?*"
                    memory: "?*"
```

Apply it:

```sh
kubectl apply -f clusterpolicy-require-limits.yaml
```

You should see the deprecation warning, then the result:

```text
Warning: kyverno.io/v1 ClusterPolicy is deprecated and will be removed in a future release; migrate to ValidatingPolicy, MutatingPolicy, GeneratingPolicy or ImageValidatingPolicy (policies.kyverno.io), see https://kyverno.io/docs/guides/migration-to-cel/
clusterpolicy.kyverno.io/require-limits created
```

Wait about ten seconds. Save this as `pod-nolimits.yaml`. It is a pod without limits and without the label `app: probe`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nolimits
  namespace: starfleet
  labels:
    app: shuttle
spec:
  containers:
    - name: nolimits
      image: curlimages/curl:8.22.0
```

Save this as `pod-probe-legacy.yaml`. It is the same pod with the label `app: probe`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: probe-legacy
  namespace: starfleet
  labels:
    app: probe
spec:
  containers:
    - name: probe-legacy
      image: curlimages/curl:8.22.0
```

Send both with a server dry run. The `--dry-run=server` flag runs the full admission and stores nothing:

```sh
kubectl create -f pod-nolimits.yaml --dry-run=server
kubectl create -f pod-probe-legacy.yaml --dry-run=server
```

You should see (the first message is shortened):

```text
Error from server: error when creating "pod-nolimits.yaml": admission webhook "validate.kyverno.svc-fail" denied the request:

resource Pod/starfleet/nolimits was blocked due to the following policies

require-limits:
...
pod/probe-legacy created (server dry run)
```

Kyverno refuses the first pod and accepts the second. Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-030/capstone/labs/lab-01 --keep
```

The checks `limits-enforced` and `probe-exempt-only` pass. Do not exclude the whole namespace and do not use `Audit`: both fail a check.

## Step 2: Refuse the latest tag with Gatekeeper

The `ConstraintTemplate` `k8sdisallowedtags` already works, so you only need a Constraint of its kind. `enforcementAction: deny` makes the Gatekeeper admission webhook refuse a pod with a violation. Save this as `constraint-no-latest-tag.yaml`:

```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sDisallowedTags
metadata:
  name: no-latest-tag
spec:
  enforcementAction: deny
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
    namespaces: ["starfleet"]
  parameters:
    tags: ["latest"]
```

Apply it:

```sh
kubectl apply -f constraint-no-latest-tag.yaml
```

Wait about ten seconds. Save this as `pod-latest-check.yaml`. It has limits, so Kyverno accepts it, and it uses the `latest` tag:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: latest-check
  namespace: starfleet
  labels:
    app: shuttle
spec:
  containers:
    - name: latest-check
      image: curlimages/curl:latest
      resources:
        limits:
          cpu: 100m
          memory: 64Mi
```

Send it with a server dry run:

```sh
kubectl create -f pod-latest-check.yaml --dry-run=server
```

You should see:

```text
Error from server (Forbidden): error when creating "pod-latest-check.yaml": admission webhook "validation.gatekeeper.sh" denied the request: [no-latest-tag] container <latest-check> uses the disallowed tag <latest>
```

Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-030/capstone/labs/lab-01 --keep
```

The check `latest-tag-denied` passes.

## Step 3: Fix beacon and check the audit

A Constraint only stops new pods. `beacon` already runs with the `latest` tag, so the Gatekeeper audit controller reports it. The audit runs about once a minute. Wait until the constraint shows a count, then read the violations:

```sh
kubectl get k8sdisallowedtags no-latest-tag -o jsonpath='{.status.totalViolations}{"\n"}{range .status.violations[*]}{.namespace}/{.name}: {.message}{"\n"}{end}'
```

You should see (the pod name has a random suffix, so yours differs):

```text
1
starfleet/beacon-798d94778f-7fp7p: container <beacon> uses the disallowed tag <latest>
```

Change the image of `beacon` to a pinned tag and wait for the rollout:

```sh
kubectl -n starfleet set image deployment/beacon beacon=curlimages/curl:8.22.0
kubectl -n starfleet rollout status deployment/beacon --timeout=120s
```

You should see `deployment.apps/beacon image updated`, some `Waiting for deployment "beacon" rollout to finish` lines and the line `deployment "beacon" successfully rolled out`. After the next audit run, the constraint shows no violation:

```sh
kubectl get k8sdisallowedtags
```

You should see:

```text
NAME            ENFORCEMENT-ACTION   TOTAL-VIOLATIONS
no-latest-tag   deny                 0
```

Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-030/capstone/labs/lab-01 --keep
```

The check `beacon-fixed-audit-clean` passes. It can wait up to four minutes for the audit run.

## Step 4: Limit replicas in production with a ValidatingAdmissionPolicy

A `ValidatingAdmissionPolicy` holds a CEL (Common Expression Language) rule that the API server evaluates, with no webhook. The rule list covers `deployments` and `deployments/scale`, because `kubectl scale` sends its request to the `deployments/scale` subresource. Save this as `validatingadmissionpolicy-replica-limit.yaml`:

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata:
  name: replica-limit
spec:
  failurePolicy: Fail
  matchConstraints:
    resourceRules:
      - apiGroups: ["apps"]
        apiVersions: ["v1"]
        operations: ["CREATE", "UPDATE"]
        resources: ["deployments", "deployments/scale"]
  validations:
    - expression: "object.spec.replicas <= 5"
      message: "Production allows at most 5 replicas."
```

A policy does nothing until a binding names it. The `Deny` binding below applies the policy to every namespace with the label `environment: production`. Save this as `validatingadmissionpolicybinding-replica-limit-production.yaml`:

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicyBinding
metadata:
  name: replica-limit-production
spec:
  policyName: replica-limit
  validationActions: ["Deny"]
  matchResources:
    namespaceSelector:
      matchLabels:
        environment: production
```

Apply both:

```sh
kubectl apply -f validatingadmissionpolicy-replica-limit.yaml
kubectl apply -f validatingadmissionpolicybinding-replica-limit-production.yaml
```

Wait about ten seconds. Save this as `deployment-six.yaml`. It has limits and a pinned tag, so only the replica rule can refuse it:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: six
  namespace: starfleet
spec:
  replicas: 6
  selector:
    matchLabels:
      app: six
  template:
    metadata:
      labels:
        app: six
    spec:
      containers:
        - name: six
          image: curlimages/curl:8.22.0
          resources:
            limits:
              cpu: 100m
              memory: 64Mi
```

Send it, then a scale of `scout` to 9:

```sh
kubectl create -f deployment-six.yaml --dry-run=server
kubectl -n starfleet scale deployment scout --replicas=9 --dry-run=server
```

You should see:

```text
The deployments "six" is invalid: : ValidatingAdmissionPolicy 'replica-limit' with binding 'replica-limit-production' denied request: Production allows at most 5 replicas.
The deployments "scout" is invalid: : ValidatingAdmissionPolicy 'replica-limit' with binding 'replica-limit-production' denied request: Production allows at most 5 replicas.
```

Change `replicas: 6` to `replicas: 5` in `deployment-six.yaml` and send it again. You should see `deployment.apps/six created (server dry run)`. Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-030/capstone/labs/lab-01 --keep
```

The check `replica-limit-in-production` passes.

## Step 5: Scale scout to 5 replicas

`scout` runs 8 replicas, which is above the new limit. A request that lowers the count to 5 passes the rule, so scale it now:

```sh
kubectl -n starfleet scale deployment scout --replicas=5
kubectl -n starfleet get deployment scout
```

You should see `deployment.apps/scout scaled`. The `READY` column can show `8/5` for a few seconds while the extra pods stop. Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-030/capstone/labs/lab-01
```

All six checks pass. Clean up:

```sh
astrona destroy ats-021-capstone-030
```
