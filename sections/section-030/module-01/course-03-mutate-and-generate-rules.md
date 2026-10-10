# Mutate And Generate Rules

Rejecting bad objects is half of a platform's job. The other half is filling in good defaults so teams do not have to, and creating the objects every namespace should have. Kyverno does both with the same rule format: a mutate rule changes an object during admission, and a generate rule creates a new object when a matching one appears. This part writes one of each and ends with the state of policy exceptions in this Kyverno version.

## A mutate rule

A mutate rule with `patchStrategicMerge` looks like a piece of the object, like a Kubernetes strategic merge patch. Kyverno merges it into every matching object before validation. The **add-if-missing anchor** `+(field)` sets a field only when the object does not have it, so the rule fills in defaults without overwriting what a team set on purpose.

<!-- astrona:playground:renew -->

Save this as `clusterpolicy-add-team-label.yaml`:

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
              kinds: ["Pod"]
              namespaces: ["starfleet"]
      mutate:
        patchStrategicMerge:
          metadata:
            labels:
              +(team): unassigned
          spec:
            securityContext:
              +(seccompProfile):
                type: RuntimeDefault
```

Apply it, then restart `scout`, which has no `team` label, and `shuttle`, which has `team: starfleet`:

```sh
kubectl apply -f clusterpolicy-add-team-label.yaml
kubectl -n starfleet rollout restart deployment scout shuttle
kubectl -n starfleet rollout status deployment scout
kubectl -n starfleet rollout status deployment shuttle
kubectl -n starfleet get pods -L team
```

You should see something like (old pods that are still terminating are left out):

```text
NAME                       READY   STATUS    RESTARTS   AGE     TEAM
beacon-9b494858-hk466      1/1     Running   0          70s     
probe-79846c4c6d-tk9m5     1/1     Running   0          40s     starfleet
scout-5ffc74c56f-p95rq     1/1     Running   0          1s      unassigned
shuttle-686fc9bd6b-fx7vc   1/1     Running   0          1s      starfleet
```

The new `scout` pod got `team: unassigned`, and `shuttle` kept its own value. `beacon` and `probe` were not restarted, so they show what they had before: a mutate rule changes objects only when they are created or updated. The seccomp default landed too:

```sh
kubectl -n starfleet get pod -l app=scout -o jsonpath='{.items[0].spec.securityContext}{"\n"}'
```

You should see:

```text
{"seccompProfile":{"type":"RuntimeDefault"}}
```

Autogen works for mutate rules as well. The restart updated the `scout` Deployment, and Kyverno changed its pod template on the way in, so the label is now in the Deployment itself: `kubectl -n starfleet get deploy scout -o jsonpath='{.spec.template.metadata.labels}'` prints `{"app":"scout","team":"unassigned"}`. A GitOps tool that manages this Deployment would now see a difference from Git, so mutate rules that touch workload templates should be agreed with the teams that own them.

## A generate rule

A generate rule creates a new resource when a matching object is created. The common platform use is a default-deny NetworkPolicy in every new namespace, so a new team starts closed and opens only what it needs. `{{request.object.metadata.name}}` is a variable: the name of the namespace that triggered the rule. `synchronize: true` makes Kyverno keep the generated object as the rule says, and recreate it if someone deletes it.

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
              namespaces: ["kube-system", "kube-public", "kube-node-lease", "kyverno", "local-path-storage"]
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

The new namespace `orbit` got its NetworkPolicy within a few seconds. `outpost` existed before the policy, and a generate rule does not touch existing objects unless the rule sets `generateExisting: true`. Now delete the generated NetworkPolicy and look again a few seconds later:

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

You can now fill in defaults with a mutate rule and its add-if-missing anchors, create and keep a default-deny NetworkPolicy in every new namespace with a generate rule, and say why a PolicyException does nothing on a default installation. Together with validate rules and reports, that covers the jobs the exam asks of Kyverno.

## Common pitfalls

> [!WARNING]
> - **Overwriting team values with a mutate rule.** Use `+(field)` to add a default only when the field is missing.
> - **Expecting a mutate rule to change running pods.** It acts on create and update requests only.
> - **Expecting a generate rule to fill existing namespaces.** That needs `generateExisting: true`.
> - **Trusting a PolicyException that was applied without errors.** Check the warning and the controller flag; on a default 1.19.1 installation, exceptions are off.
