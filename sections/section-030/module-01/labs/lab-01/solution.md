# Solution

The policy selects the resources it owns and changes only the behavior assigned in this exercise.

Save this as `practice-solution.yaml`:

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
          kinds:
          - Pod
          namespaces:
          - starfleet
    validate:
      failureAction: Enforce
      message: Every container in starfleet must set resources.limits.cpu and resources.limits.memory.
      pattern:
        spec:
          containers:
          - resources:
              limits:
                cpu: ?*
                memory: ?*
```

Apply it:

```sh
kubectl apply -f practice-solution.yaml
```

Check the result:

```sh
kubectl -n starfleet run missing-limits --image=curlimages/curl:8.22.0 --dry-run=server
kubectl -n outpost run outside-scope --image=curlimages/curl:8.22.0 --dry-run=server
```

Use the returned objects and decisions to check every task. A denied request must identify the expected access or policy restriction; a connection failure is not evidence that the restriction works.
