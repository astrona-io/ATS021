# Generate And Maintain Namespace Policy

A new application namespace may need a NetworkPolicy before a team deploys workloads. A Kyverno generate rule asks the background controller to create that separate resource. Generation and mutation have different evidence: inspect the generated object and its reconciliation after deletion.

## A generate rule

A generate rule creates a new resource when a matching object is created. The common platform use is a default-deny NetworkPolicy in every new namespace, so a new team starts closed and opens only what it needs. `{{request.object.metadata.name}}` is a variable: the name of the namespace that triggered the rule. `synchronize: true` makes Kyverno keep the generated object as the rule says, and recreate it if someone deletes it.

<!-- astrona:playground:renew -->

Save this as `clusterpolicy-default-deny-networkpolicy.yaml`:

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
              names: ["kube-system", "kube-public", "kube-node-lease", "kyverno", "local-path-storage"]
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

Apply it, create a new namespace, and look for the NetworkPolicy:

```sh
kubectl apply -f clusterpolicy-default-deny-networkpolicy.yaml
kubectl create namespace orbit
kubectl -n orbit get networkpolicy
kubectl -n outpost get networkpolicy
```

You should see something like:

```text
clusterpolicy.kyverno.io/default-deny-networkpolicy created
namespace/orbit created
NAME           POD-SELECTOR   AGE
default-deny   <none>         4s
No resources found in outpost namespace.
```

The exclude rule uses `names` because Namespace is a cluster-scoped object. The new namespace `orbit` got its NetworkPolicy within a few seconds. `outpost` existed before the policy, and a generate rule does not touch existing objects unless the rule sets `generateExisting: true`. Now delete the generated NetworkPolicy and look again a few seconds later:

```sh
kubectl -n orbit delete networkpolicy default-deny
kubectl -n orbit get networkpolicy
```

You should see something like:

```text
networkpolicy.networking.k8s.io "default-deny" deleted from orbit namespace
NAME           POD-SELECTOR   AGE
default-deny   <none>         5s
```

`synchronize: true` brought it back. A team cannot remove the platform's default by deleting it; the change has to go through the policy.

## Exceptions in Kyverno 1.19.1

Sometimes one workload must be allowed to break a rule, for a documented reason. Weakening the policy for everyone is the wrong answer. Kyverno's answer is the **PolicyException** resource: it names a policy, the rules, and the objects that are exempt. On a default Kyverno 1.19.1 installation, though, exceptions are switched off. The controllers run with the flag `--enablePolicyException=false`, and applying a PolicyException prints:

```text
Warning: PolicyException resources would not be processed until it is enabled.
```

The object is stored, and it has no effect. To use exceptions, an administrator sets `--enablePolicyException=true` on the Kyverno controllers, usually through the installation's settings, and should also limit the namespaces that may hold exceptions with `--exceptionNamespace`, so not every team can exempt itself. Kyverno 1.19.1 also marks the `kyverno.io/v2` PolicyException as deprecated in favour of the PolicyException in `policies.kyverno.io`. Whatever version you meet, check that exceptions are enabled before you rely on one, and prove an exception the same way as a policy: apply the object it should exempt and read the answer.

A generated NetworkPolicy proves that Kyverno created and maintains the object. Traffic isolation also requires a network plugin that enforces NetworkPolicy; this kind playground does not test that enforcement.

## Common pitfalls

> [!WARNING]
> - Existing namespaces need `generateExisting: true` if they should also receive the resource.
> - Exclude system namespaces from application defaults.
> - A PolicyException has no effect unless exception processing is enabled.
