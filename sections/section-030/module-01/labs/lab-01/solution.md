# Solution

Solve this lab on `terminal`. The output below comes from a real run of this lab. Long Kyverno messages are shortened where the text says so.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-030/module-01/labs/lab-01
```

Keep this command running in a second host terminal. It grades the lab every few seconds and records nothing:

```sh
astrona submit --watch --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-030/module-01/labs/lab-01
```

Use `--watch` until the end, because a plain `astrona submit` finishes the attempt and deletes the lab. Run the plain command once, in the last step.

The watch terminal right after the start shows one check that already passes. `limits-rule-allows-good-pods` passes because no policy exists yet, so every pod is accepted. It stays your guard: it fails if your policy blocks pods that have both limits, or if it reaches `outpost`.

## Step 1: Refuse pods without CPU and memory limits

A `validate` rule with `failureAction: Enforce` makes the Kyverno admission webhook reject a request that fails the pattern. Kyverno also generates an extra rule for Deployments, named `autogen-require-cpu-memory-limits`, so a Deployment whose pod template has no limits is refused too. Save this as `clusterpolicy-require-limits.yaml`:

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

Wait about ten seconds. Then send a pod without limits to `starfleet` and the same pod to `outpost`. The `--dry-run=server` flag runs the full admission but stores nothing:

```sh
kubectl -n starfleet run nolimits --image=curlimages/curl:8.22.0 --dry-run=server
kubectl -n outpost run plain --image=curlimages/curl:8.22.0 --dry-run=server
```

You should see (the first message is shortened):

```text
Error from server: admission webhook "validate.kyverno.svc-fail" denied the request:
... require-limits: require-cpu-memory-limits: 'validation error: Every container in starfleet must set resources.limits.cpu and resources.limits.memory. rule require-cpu-memory-limits failed at path /spec/containers/0/resources/limits/'
pod/plain created (server dry run)
```

A Deployment without limits fails at the same place, but the rule name is `autogen-require-cpu-memory-limits` and the path starts with `/spec/template/spec/containers/0/`.

The watch terminal now shows the check `limits-rule-rejects-pods` passing. Do not set `failureAction: Audit`: it only records the failure and the pod is still created.

## Step 2: Add a default team label

A `mutate` rule changes the pod before the API server stores it. The `+(team)` anchor adds the label only when the pod has no `team` label. Save this as `clusterpolicy-add-team-label.yaml`:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: add-team-label
spec:
  rules:
    - name: add-default-team
      match:
        any:
          - resources:
              kinds: ["Pod"]
              namespaces: ["starfleet"]
      mutate:
        patchStrategicMerge:
          metadata:
            labels:
              +(team): unassigned
```

Apply it:

```sh
kubectl apply -f clusterpolicy-add-team-label.yaml
```

Wait about ten seconds. Then test two pods. Both set the limits, so the first policy accepts them. Save this as `pod-labelcheck.yaml`. It has no `team` label:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: labelcheck
  namespace: starfleet
spec:
  containers:
    - name: labelcheck
      image: curlimages/curl:8.22.0
      resources:
        limits:
          cpu: 100m
          memory: 64Mi
```

Save this as `pod-teamcheck.yaml`. It already has `team: blue`:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: teamcheck
  namespace: starfleet
  labels:
    team: blue
spec:
  containers:
    - name: teamcheck
      image: curlimages/curl:8.22.0
      resources:
        limits:
          cpu: 100m
          memory: 64Mi
```

Send both with a server dry run and print the `team` label of the result:

```sh
kubectl create -f pod-labelcheck.yaml --dry-run=server -o jsonpath='{.metadata.labels.team}{"\n"}'
kubectl create -f pod-teamcheck.yaml --dry-run=server -o jsonpath='{.metadata.labels.team}{"\n"}'
```

You should see:

```text
unassigned
blue
```

The first pod got `team: unassigned`. The second kept `team: blue`.

The watch terminal now shows the check `team-label-default` passing.

## Step 3: Generate a default-deny NetworkPolicy in new namespaces

A `generate` rule creates a new object when a matching object appears. Here the trigger is a `Namespace`. With `synchronize: true`, Kyverno also puts the NetworkPolicy back if someone deletes it. The `exclude` block skips the system namespaces. Save this as `clusterpolicy-default-deny-networkpolicy.yaml`:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: default-deny-networkpolicy
spec:
  rules:
    - name: generate-default-deny
      match:
        any:
          - resources:
              kinds: ["Namespace"]
      exclude:
        any:
          - resources:
              namespaces: ["kube-system", "kube-public", "kube-node-lease", "kyverno", "local-path-storage"]
      generate:
        apiVersion: networking.k8s.io/v1
        kind: NetworkPolicy
        name: default-deny
        namespace: "{{request.object.metadata.name}}"
        synchronize: true
        data:
          spec:
            podSelector: {}
            policyTypes:
              - Ingress
              - Egress
```

Apply it:

```sh
kubectl apply -f clusterpolicy-default-deny-networkpolicy.yaml
```

Create a test namespace and read the generated policy:

```sh
kubectl create namespace orbit
kubectl -n orbit get networkpolicy
```

You should see the NetworkPolicy `default-deny` with the pod selector `<none>` in the `POD-SELECTOR` column, which means it selects all pods. Delete the test namespace when you are done:

```sh
kubectl delete namespace orbit
```

Check that all three policies are ready:

```sh
kubectl get clusterpolicy
```

You should see `READY` as `True` and `MESSAGE` as `Ready` for `require-limits`, `add-team-label` and `default-deny-networkpolicy`. Right after an apply, `READY` can be empty for a few seconds. Press Ctrl-C to stop the watch, then run the grader once:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-030/module-01/labs/lab-01
```

All four checks pass. Clean up:

```sh
astrona destroy ats-021-lab-030-01
```
