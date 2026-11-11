# Solution

The policy selects the resources it owns and changes only the behavior assigned in this exercise.

Save this as `practice-solution.yaml`:

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
          kinds:
          - Pod
          namespaces:
          - starfleet
    mutate:
      patchStrategicMerge:
        metadata:
          labels:
            +(team): unassigned
```

Apply it:

```sh
kubectl apply -f practice-solution.yaml
```

Check the result:

```sh
kubectl -n starfleet run label-default --image=curlimages/curl:8.22.0 --dry-run=server -o yaml
kubectl -n starfleet run label-kept --labels=team=blue --image=curlimages/curl:8.22.0 --dry-run=server -o yaml
kubectl -n outpost run label-control --image=curlimages/curl:8.22.0 --dry-run=server -o yaml
```

Use the returned objects and decisions to check every task. A denied request must identify the expected access or policy restriction; a connection failure is not evidence that the restriction works.
