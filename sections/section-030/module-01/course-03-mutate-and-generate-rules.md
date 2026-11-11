# Add Defaults With Mutation

Kyverno can add a default during admission while preserving a value supplied by the application team. A mutate rule changes the admitted object. An add-if-missing anchor makes that change conditional on the field being absent.

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

Check both an object with the field absent and an object with an explicit value. An out-of-scope namespace provides a control for the rule’s match.

## Common pitfalls

> [!WARNING]
> - Use `+(field)` when a default must preserve an existing value.
> - An admission mutation does not rewrite every running Pod.
> - Scope the rule so unrelated namespaces keep their own defaults.
