# Solution

Enable baseline warnings on the three application namespaces:

```sh
kubectl label --overwrite namespace navigation telemetry research pod-security.kubernetes.io/warn=baseline
```

```text
namespace/navigation labeled
namespace/telemetry labeled
namespace/research labeled
```

The `warn` label makes Pod Security Admission print a warning on future admission requests. Pod Security Admission is the built-in admission controller that checks Pods against a Pod Security Standards level. It does not check the Pods that already run just because the label changed. To get a warning for a running Pod, send its specification to the API server again.

The fastest way to do that is a test namespace with the same label. Create it and label it:

```sh
kubectl create namespace test-namespace
kubectl label namespace test-namespace pod-security.kubernetes.io/warn=baseline
```

```text
namespace/test-namespace created
namespace/test-namespace labeled
```

Now save each running `scout` Pod to a file. The saved YAML contains the line `namespace: <original namespace>` under `metadata`, and `kubectl` refuses to send such a file to another namespace. The `grep -v` command removes that one line:

```sh
for namespace in navigation telemetry research; do
  kubectl -n "$namespace" get pod scout -o yaml | grep -v '^  namespace: ' > "pod-scout-$namespace.yaml"
done
```

Apply the three files to `test-namespace` with a server-side dry run. With `--dry-run=server`, the API server runs admission, including Pod Security Admission, but does not store the object. So the task rule "do not add more Pods" still holds:

```sh
for namespace in navigation telemetry research; do
  echo "Checking $namespace"
  kubectl -n test-namespace apply --dry-run=server -f "pod-scout-$namespace.yaml"
done
```

In this run the Pod from `navigation` is the one that violates baseline. Your namespace can be a different one:

```text
Checking navigation
Warning: would violate PodSecurity "baseline:latest": privileged (container "app" must not set securityContext.privileged=true)
pod/scout created (server dry run)
Checking telemetry
pod/scout created (server dry run)
Checking research
pod/scout created (server dry run)
```

Only one file produces a warning. The warning names the cause: the container sets `securityContext.privileged: true`, which baseline forbids. The other two Pods pass baseline, even though they do not meet the stricter restricted level.

Use the namespace from the warning below, replacing `<NAMESPACE-WITH-VIOLATION>`. Confirm the cause in the specification of the running Pod:

```sh
kubectl -n <NAMESPACE-WITH-VIOLATION> get pod scout -o yaml
```

Under `spec.containers` the output shows this field (output shortened):

```text
    securityContext:
      privileged: true
```

Keep the Pod running and record the finding on its namespace. Then delete the test namespace and check the labels:

```sh
kubectl label namespace <NAMESPACE-WITH-VIOLATION> security-review=required --overwrite
kubectl delete namespace test-namespace
kubectl get namespace navigation telemetry research -L pod-security.kubernetes.io/warn,security-review,pod-security.kubernetes.io/enforce
```

```text
NAME         STATUS   AGE   WARN       SECURITY-REVIEW   ENFORCE
navigation   Active   30s   baseline   required          
telemetry    Active   30s   baseline                     
research     Active   30s   baseline                     
```

All three rows must show baseline in the warn column. Only the namespace identified by the warning should show required in the security-review column. The enforce column must remain empty. `security-review` is a custom inventory label; it does not enable any Pod Security enforcement.
