# Proving And Debugging Access

A missing permission rarely announces itself as "add `patch` on `deployments/scale` in `apps`". It shows up as a failed pipeline step or a controller that logs `Forbidden` a hundred times a minute. This part gives you two habits that turn those symptoms into one line of YAML: list everything an identity can do, and read a `Forbidden` error field by field.

## Everything one identity can do

`kubectl auth can-i --list` asks the API server for every rule that applies to an identity in one namespace. With `--as`, you can run it for any identity:

<!-- astrona:playground:renew -->

```sh
kubectl auth can-i --list -n starfleet --as=system:serviceaccount:starfleet:ci-deployer
```

You should see something like this (shortened; the full list ends with many `Non-Resource URLs` such as `/healthz` and `/version`):

```text
Resources                                       Non-Resource URLs                      Resource Names   Verbs
selfsubjectreviews.authentication.k8s.io        []                                     []               [create]
selfsubjectaccessreviews.authorization.k8s.io   []                                     []               [create]
selfsubjectrulesreviews.authorization.k8s.io    []                                     []               [create]
deployments.apps                                []                                     []               [get list watch create update patch]
services                                        []                                     []               [get list]
                                                [/.well-known/openid-configuration/]   []               [get]
                                                [/api/*]                               []               [get]
...
```

Two rows come from your `ci-deployer` Role: `deployments.apps` and `services`. The `self...` rows and the URL rows come from built-in ClusterRoles that every authenticated identity has. They let any identity ask about its own rights and read the API's discovery and health endpoints. When an identity can do more than you expect, the extra row in this list is where you start.

## Reading a Forbidden error

Every `Forbidden` error from RBAC has the same shape. Try to delete a Deployment as the pipeline. `--dry-run=server` sends the request through the full API server path, including authorization, but never stores the result:

```sh
kubectl -n starfleet delete deployment scout --as=system:serviceaccount:starfleet:ci-deployer --dry-run=server
```

You should see:

```text
Error from server (Forbidden): deployments.apps "scout" is forbidden: User "system:serviceaccount:starfleet:ci-deployer" cannot delete resource "deployments" in API group "apps" in the namespace "starfleet"
```

The message holds every field a rule needs, in a fixed order:

| Part of the message | Rule field |
| --- | --- |
| `User "system:serviceaccount:starfleet:ci-deployer"` | The subject to bind |
| `cannot delete` | `verbs` |
| `resource "deployments"` | `resources` |
| `in API group "apps"` | `apiGroups` |
| `in the namespace "starfleet"` | Where the binding must live |

When the resource is in the core group, the message says `in API group ""`, and the rule needs `apiGroups: [""]`. When the request is for a cluster-wide resource, the message ends with `at the cluster scope` instead of a namespace, and only a ClusterRoleBinding can fix it.

If you do not know a resource's group, ask the API server. `kubectl api-resources` lists every resource with its group and version, and whether it lives in a namespace:

```sh
kubectl api-resources --api-group=apps
```

You should see:

```text
NAME                  SHORTNAMES   APIVERSION   NAMESPACED   KIND
controllerrevisions                apps/v1      true         ControllerRevision
daemonsets            ds           apps/v1      true         DaemonSet
deployments           deploy       apps/v1      true         Deployment
replicasets           rs           apps/v1      true         ReplicaSet
statefulsets          sts          apps/v1      true         StatefulSet
```

The `APIVERSION` column is `<group>/<version>`. A resource whose version has no group part, such as `v1` for pods and Services, is in the core group `""`.

## Subresources

Some actions are not on the resource itself but on a **subresource**: a part of a resource with its own API path and its own RBAC entry. The common ones are `pods/log` (read container logs), `pods/exec` (run a command in a container), `pods/portforward`, and `deployments/scale` (change the replica count). A rule must list a subresource by its full name, for example `resources: ["pods/exec"]`.

The `view` ClusterRole shows the difference. `dev-anna` in the group `developers` can read logs but cannot open a shell:

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

`scout` restarts, and `probe` is refused at the first step, the `get`. A rule with `resourceNames` cannot allow `list`, `watch` or `create` in a useful way, because those requests do not name one object. Keep `resourceNames` for actions on objects that already exist.

You can now list everything an identity may do, turn any `Forbidden` message into the exact rule that is missing, check subresources the right way, and limit a rule to one object. The open question is the reverse problem: finding identities that can do far more than they should, and adding rights to the built-in roles without breaking them.

## Common pitfalls

> [!WARNING]
> - **Checking a subresource with `can-i verb resource/subresource`.** The part after `/` is read as an object name. Use `--subresource`.
> - **Granting `pods` and expecting `exec` to work.** `pods/exec`, `pods/log` and `deployments/scale` are separate entries in a rule.
> - **Adding `list` to a rule with `resourceNames`.** A list request does not name an object, so the rule does not allow it.
> - **Reading only the first half of a Forbidden error.** The group and the namespace at the end decide which rule and which binding you need.
