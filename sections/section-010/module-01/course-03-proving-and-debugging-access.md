# Proving And Debugging Access

A failed request identifies the identity, verb, resource, API group and namespace that Kubernetes checked. Read those fields before changing a Role. A successful request and a denied control together show whether the new grant has the intended scope.

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

Use the error to identify the missing rule, then check both the intended operation and an operation that must stay denied.

## Common pitfalls

> [!WARNING]
> - Read the API group and namespace as well as the verb in a Forbidden error.
> - A denied request is useful evidence only when the corresponding allowed request also works.
