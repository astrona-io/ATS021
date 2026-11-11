# Solution Walkthrough

Inspect `kubectl get constrainttemplate k8sdisallowedtags -o yaml`. Correct the Rego syntax and reference the plural `input.parameters.tags`. The lesson shows the complete working template; `solution/solution.yaml` contains the reference version.

Apply the repaired template and wait for its generated constraint kind:

```sh
kubectl apply -f fixed-template.yaml
kubectl wait --for=condition=Established crd/k8sdisallowedtags.constraints.gatekeeper.sh --timeout=120s
```

Create the `no-latest-tag` constraint from the lesson with `enforcementAction: deny`, namespace `starfleet` and parameter `tags: ["latest"]`. Apply it, then compare admission decisions:

```sh
kubectl -n starfleet run denied --image=curlimages/curl:latest --dry-run=server
kubectl -n starfleet run pinned --image=curlimages/curl:8.22.0 --dry-run=server
kubectl -n outpost run outside --image=curlimages/curl:latest --dry-run=server
```

Only the first request should be denied, with a message naming `no-latest-tag`. A timeout or unavailable webhook does not prove that the rule works. Check `status.created` on the template and the constraint's status if the expected denial does not appear.
