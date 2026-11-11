# Solution Walkthrough

The template already compiles. Inspect its parameter schema and the existing Pod, then save this as `audit-latest.yaml`:

```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sDisallowedTags
metadata:
  name: audit-latest-outpost
spec:
  enforcementAction: dryrun
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
    namespaces: ["outpost"]
  parameters:
    tags: ["latest"]
```

Apply the constraint and wait for an audit cycle:

```sh
kubectl apply -f audit-latest.yaml
kubectl get k8sdisallowedtags audit-latest-outpost -o yaml
kubectl -n outpost get pods -l app=drifter -o wide
kubectl -n outpost run audit-control --image=curlimages/curl:latest --dry-run=server
kubectl -n outpost run pinned-control --image=curlimages/curl:8.22.0 --dry-run=server
kubectl -n starfleet run scope-control --image=curlimages/curl:latest --dry-run=server
```

The constraint's `status.auditTimestamp` identifies the scan, and `status.violations` should name the existing drifter Pod. All three dry-run requests should be accepted. Audit reports a violation without evicting a running Pod or denying a new request.
