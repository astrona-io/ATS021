# Solution Walkthrough

Use the template and constraint from the preceding registry lesson, saved as `constrainttemplate-k8sallowedregistries.yaml` and `k8sallowedregistries-ghcr-only.yaml`. The complete reference files also live in `solution/`.

```sh
kubectl apply -f constrainttemplate-k8sallowedregistries.yaml
kubectl wait --for=condition=Established crd/k8sallowedregistries.constraints.gatekeeper.sh --timeout=120s
kubectl apply -f k8sallowedregistries-ghcr-only.yaml
kubectl -n starfleet run allowed --image=ghcr.io/stefanprodan/podinfo:6.15.0 --dry-run=server
kubectl -n starfleet run denied --image=docker.io/library/nginx:latest --dry-run=server
kubectl -n starfleet run lookalike --image=ghcr.io.example.com/team/app:v1 --dry-run=server
kubectl -n outpost run outside --image=docker.io/library/nginx:latest --dry-run=server
```

Repeat the first three checks in `starfleet-prod`. Allowed and outside requests should succeed. Both denied requests must name `ghcr-only`; a network error is not policy evidence. The slash in `ghcr.io/` establishes the end of the registry host.

For the multi-container control, save a Pod manifest with one GHCR image and one Docker Hub image, then run `kubectl create --dry-run=server -f two-containers.yaml`. The template iterates over all regular containers, so the second image must still cause rejection.
