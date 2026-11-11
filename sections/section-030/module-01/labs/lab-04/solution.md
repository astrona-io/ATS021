# Solution

The policy selects the resources it owns and changes only the behavior assigned in this exercise.

Save this as `practice-solution.yaml`:

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
          kinds:
          - Namespace
    exclude:
      any:
      - resources:
          names:
          - kube-system
          - kube-public
          - kube-node-lease
          - kyverno
          - local-path-storage
    generate:
      apiVersion: networking.k8s.io/v1
      kind: NetworkPolicy
      name: default-deny
      namespace: '{{request.object.metadata.name}}'
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
kubectl apply -f practice-solution.yaml
```

Check the result:

```sh
kubectl create namespace practice-generated
kubectl -n practice-generated get networkpolicy default-deny -o yaml
kubectl -n practice-generated delete networkpolicy default-deny
kubectl -n practice-generated get networkpolicy default-deny -w
```

Wait for the policy to reappear, stop the watch with Ctrl-C, then remove the temporary namespace with `kubectl delete namespace practice-generated`. Generation does not prove traffic isolation; that requires an enforcing network plugin.

Use the returned objects and decisions to check every task. A denied request must identify the expected access or policy restriction; a connection failure is not evidence that the restriction works.
