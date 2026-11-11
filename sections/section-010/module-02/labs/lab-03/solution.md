# Solution

Enable baseline warnings on the three application namespaces:

```sh
kubectl label --overwrite namespace navigation telemetry research pod-security.kubernetes.io/warn=baseline
```

This setting reports violations on future admission requests. It does not scan existing Pods just because the warning label changed. Preview a baseline enforcement label separately on each namespace:

```sh
for namespace in navigation telemetry research; do
  echo "Checking $namespace"
  kubectl label --dry-run=server --overwrite namespace "$namespace" \
    pod-security.kubernetes.io/enforce=baseline \
    pod-security.kubernetes.io/enforce-version=v1.35
done
```

The namespace containing the privileged Pod produces a warning about existing Pods violating the new enforce level. The server evaluates the change but does not save it. The other two namespaces have no baseline violations, even though their Pods do not satisfy the stricter restricted level.

Use the namespace named in that warning below, replacing `<NAMESPACE-WITH-VIOLATION>`:

```sh
kubectl -n <NAMESPACE-WITH-VIOLATION> get pod scout -o yaml
```

The container has `securityContext.privileged: true`, which baseline forbids. Keep the Pod running and record the finding on its namespace:

```sh
kubectl label namespace <NAMESPACE-WITH-VIOLATION> security-review=required --overwrite
kubectl get namespace navigation telemetry research -L pod-security.kubernetes.io/warn,security-review,pod-security.kubernetes.io/enforce
```

All three rows must show baseline in the warn column. Only the namespace identified by the warning should show required in the security-review column. The enforce column must remain empty. `security-review` is a custom inventory label; it does not enable any Pod Security enforcement.
