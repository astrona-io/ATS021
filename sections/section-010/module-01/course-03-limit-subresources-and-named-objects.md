# Limit Subresources And Named Objects

A service account may need to change a replica count without permission to change an image or a pod template. Kubernetes exposes scaling through a subresource with its own authorization check. Named-object rules narrow that permission further. The playground commands use the `ci-deployer` Role and the `developers` binding already created there; the next lab starts independently.

## Subresources

Some actions are not on the resource itself but on a **subresource**: a part of a resource with its own API path and its own RBAC entry. The common ones are `pods/log` (read container logs), `pods/exec` (run a command in a container), `pods/portforward`, and `deployments/scale` (change the replica count). A rule must list a subresource by its full name, for example `resources: ["pods/exec"]`.

The `view` ClusterRole shows the difference. `dev-anna` in the group `developers` can read logs but cannot open a shell:

<!-- astrona:playground:renew -->

```sh
kubectl -n starfleet exec deploy/shuttle --as=dev-anna --as-group=developers -- true
```

You should see something like:

```text
Error from server (Forbidden): pods "shuttle-75fc875874-qk64r" is forbidden: User "dev-anna" cannot create resource "pods/exec" in API group "" in the namespace "starfleet"
```

The verb for `exec` is `create` and the resource is `pods/exec`. The same happens to the pipeline when it tries `kubectl scale`: the error says `cannot patch resource "deployments/scale"`, because `patch` on `deployments` does not include the `scale` subresource.

`kubectl auth can-i` needs care here. It reads `deployments/scale` as "the Deployment named `scale`", not as the subresource. Use `--subresource` instead:

```sh
kubectl auth can-i patch deployments/scale -n starfleet --as=system:serviceaccount:starfleet:ci-deployer
kubectl auth can-i patch deployments --subresource=scale -n starfleet --as=system:serviceaccount:starfleet:ci-deployer
```

You should see:

```text
yes
no
```

The first answer is about a Deployment named `scale`, which the pipeline may patch like any other Deployment. The second is the real question, and the answer is `no`, which matches the `Forbidden` error.

## Rights on one named object

`resourceNames` limits a rule to objects with given names. `dev-anna` should be able to restart the `scout` Deployment, and nothing else. A restart with `kubectl rollout restart` reads the Deployment and patches its pod template.

Save this as `role-scout-restarter.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: scout-restarter
  namespace: starfleet
rules:
  - apiGroups: ["apps"]
    resources: ["deployments"]
    resourceNames: ["scout"]
    verbs: ["get", "patch"]
```

Save this as `rolebinding-scout-restarter.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: scout-restarter
  namespace: starfleet
subjects:
  - kind: User
    name: dev-anna
    apiGroup: rbac.authorization.k8s.io
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: scout-restarter
```

Apply both, then restart `scout` and `probe` as `dev-anna`, without the group this time:

```sh
kubectl apply -f role-scout-restarter.yaml -f rolebinding-scout-restarter.yaml
kubectl -n starfleet rollout restart deployment scout --as=dev-anna
kubectl -n starfleet rollout restart deployment probe --as=dev-anna
```

You should see:

```text
role.rbac.authorization.k8s.io/scout-restarter created
rolebinding.rbac.authorization.k8s.io/scout-restarter created
deployment.apps/scout restarted
Error from server (Forbidden): deployments.apps "probe" is forbidden: User "dev-anna" cannot get resource "deployments" in API group "apps" in the namespace "starfleet"
```

`scout` restarts, and `probe` is refused at the first step, the `get`. For `list` or `watch` restricted by `resourceNames`, the client must include a matching `metadata.name` field selector. Top-level `create` and `deletecollection` requests cannot be restricted this way. The restart here uses `get` and `patch` on an existing named Deployment.

A scale request needs permission on `deployments/scale`; permission on `deployments` alone does not grant it. Combine the correct resource path with `resourceNames` when only one Deployment should be affected.

## Common pitfalls

> [!WARNING]
> - Use `--subresource=scale` with `kubectl auth can-i`; a slash in its resource argument can mean an object name.
> - Check the parent Deployment and the scale subresource separately.
> - Keep named-object grants limited to the operations the workload needs.
