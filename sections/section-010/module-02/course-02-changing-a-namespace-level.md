# Inspect Existing Pod Security Violations

A warning label affects admission requests; it does not scan every Pod already running. Preview a namespace enforcement change to find existing violations without changing or replacing those Pods. Confirm the warning against the Pod specification before recording the finding.

## Test the change before you make it

A namespace label change goes through the API server like any other request. When an enforce level or version changes with `--dry-run=server`, Pod Security Admission checks existing pods in the namespace against the new level and prints a warning for each one that would break it. Nothing is changed.

<!-- astrona:playground:renew -->

```sh
kubectl label --dry-run=server --overwrite namespace starfleet pod-security.kubernetes.io/enforce=restricted
```

You should see something like:

```text
Warning: existing pods in namespace "starfleet" violate the new PodSecurity enforce level "restricted:latest"
Warning: privileged-debug-748b7d59f4-8qx5g: privileged, allowPrivilegeEscalation != false, unrestricted capabilities, restricted volume types, runAsNonRoot != true, seccompProfile
Warning: probe-6f569ff97-mftq2 (and 2 other pods): allowPrivilegeEscalation != false, unrestricted capabilities, runAsNonRoot != true, seccompProfile
namespace/starfleet labeled (server dry run)
```

Every pod in `starfleet` breaks `restricted`. Pods with the same failures are grouped: `probe` stands for itself, `scout` and `shuttle`, which miss the same four settings. Now test `baseline`:

```sh
kubectl label --dry-run=server --overwrite namespace starfleet pod-security.kubernetes.io/enforce=baseline
```

You should see something like:

```text
Warning: existing pods in namespace "starfleet" violate the new PodSecurity enforce level "baseline:latest"
Warning: privileged-debug-748b7d59f4-8qx5g: hostPath volumes, privileged
namespace/starfleet labeled (server dry run)
```

Only `privileged-debug` breaks `baseline`. The ordinary workloads pass it unchanged, which is typical. That gives a plan: enforce `baseline` now, and report `restricted` until the workloads are fixed.

## Find existing violations across namespaces

Setting `warn=baseline` reports violations on later admission requests. Adding that warning label alone does not scan Pods that are already running. To review existing workloads, preview an **enforce** label change with `--dry-run=server` in each target namespace. Neither this dry run nor adding a warning label evicts a running Pod.

The playground has two application namespaces. Check each one and print its name before the result:

```sh
for namespace in starfleet outpost; do
  echo "Checking $namespace"
  kubectl label --dry-run=server --overwrite namespace "$namespace" \
    pod-security.kubernetes.io/enforce=baseline \
    pod-security.kubernetes.io/enforce-version=v1.35
done
```

Inspect the Pod named by a warning with `kubectl get pod -n NAMESPACE POD -o yaml`, replacing the uppercase values. Check the fields named in the warning. Baseline permits some settings that restricted forbids, so a restricted warning does not prove a baseline violation.

A custom namespace label can record a confirmed finding for a later review. In this playground, `starfleet` contains `privileged-debug`, whose privileged container and hostPath volume violate baseline:

```sh
kubectl label namespace starfleet security-review=required --overwrite
kubectl get namespace starfleet outpost -L security-review
```

`security-review` is an inventory label, not a Pod Security setting. It does not block requests or repair the Pod. When reviewing more namespaces, apply the same inspection to each one and label only those with confirmed violations.

The inventory label records a confirmed finding. It neither enforces Pod Security Standards nor repairs a workload.

## Common pitfalls

> [!WARNING]
> - Adding `warn=baseline` does not retrospectively inspect running Pods.
> - Compare a warning against the intended level: a restricted violation may still pass baseline.
> - Use a server-side dry run to inspect existing Pods without enabling enforcement.
