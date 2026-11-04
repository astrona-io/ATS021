# Solution

Solve this lab on `terminal`. The output below comes from a real run of this lab.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-010/module-01/labs/lab-01
```

Keep this command running in a second host terminal. It grades the lab every few seconds and records nothing:

```sh
astrona submit --watch --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-010/module-01/labs/lab-01
```

Use `--watch` until the end, because a plain `astrona submit` finishes the attempt and deletes the lab. Run the plain command once, in the last step.

The watch terminal right after the start shows one check that already passes. `ci-deployer-least-privilege` passes because `ci-deployer` has no rights yet. It stays your guard while you add the Role.

## Step 1: Give ci-deployer the Deployment rights

A Role holds the rules in one namespace. A RoleBinding gives them to the service account. Create both:

```sh
kubectl create role deployment-manager -n starfleet --verb=get,list,watch,create,update,patch --resource=deployments.apps
kubectl create rolebinding ci-deployer-deployment-manager -n starfleet --role=deployment-manager --serviceaccount=starfleet:ci-deployer
```

You should see:

```text
role.rbac.authorization.k8s.io/deployment-manager created
rolebinding.rbac.authorization.k8s.io/ci-deployer-deployment-manager created
```

Check the allowed verb and the verb that must stay forbidden:

```sh
kubectl auth can-i patch deployments.apps -n starfleet --as=system:serviceaccount:starfleet:ci-deployer
kubectl auth can-i delete deployments.apps -n starfleet --as=system:serviceaccount:starfleet:ci-deployer
```

You should see:

```text
yes
no
```

The watch terminal now shows the checks `ci-deployer-can-manage-deployments` and `ci-deployer-least-privilege` passing.

## Step 2: Remove cluster-admin from legacy-agent

Find the ClusterRoleBinding that names `legacy-agent`:

```sh
kubectl get clusterrolebindings -o json | jq -r '.items[] | select(.roleRef.name=="cluster-admin") | .metadata.name + "  " + ([.subjects[]? | .kind + ":" + (.namespace // "") + "/" + .name] | join(", "))'
```

You should see:

```text
cluster-admin  Group:/system:masters
kubeadm:cluster-admins  Group:/kubeadm:cluster-admins
legacy-agent-admin  ServiceAccount:starfleet/legacy-agent
```

The first two bindings belong to every kind cluster. Delete only `legacy-agent-admin`, then give the agent a Role for pods:

```sh
kubectl delete clusterrolebinding legacy-agent-admin
kubectl create role pod-reader -n starfleet --verb=get,list,watch --resource=pods
kubectl create rolebinding legacy-agent-pod-reader -n starfleet --role=pod-reader --serviceaccount=starfleet:legacy-agent
```

You should see:

```text
clusterrolebinding.rbac.authorization.k8s.io "legacy-agent-admin" deleted
role.rbac.authorization.k8s.io/pod-reader created
rolebinding.rbac.authorization.k8s.io/legacy-agent-pod-reader created
```

Check that the agent reads pods in `starfleet` but not in `outpost`:

```sh
kubectl auth can-i list pods -n starfleet --as=system:serviceaccount:starfleet:legacy-agent
kubectl auth can-i list pods -n outpost --as=system:serviceaccount:starfleet:legacy-agent
```

You should see:

```text
yes
no
```

The watch terminal now shows the checks `legacy-agent-cluster-admin-removed` and `legacy-agent-reads-pods-only` passing. Do not delete the service account, and do not bind `view` with a ClusterRoleBinding: both fail a check.

## Step 3: Extend view with an aggregated ClusterRole

Check the start state:

```sh
kubectl auth can-i list leases.coordination.k8s.io -n starfleet --as=dev-anna --as-group=developers
```

It prints `no`. Save this as `clusterrole-view-leases.yaml`:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: view-leases
  labels:
    rbac.authorization.k8s.io/aggregate-to-view: "true"
rules:
  - apiGroups: ["coordination.k8s.io"]
    resources: ["leases"]
    verbs: ["get", "list", "watch"]
```

Apply it:

```sh
kubectl apply -f clusterrole-view-leases.yaml
```

Then check the result:

```sh
kubectl auth can-i list leases.coordination.k8s.io -n starfleet --as=dev-anna --as-group=developers
```

The API server prints `clusterrole.rbac.authorization.k8s.io/view-leases created`, and the check prints:

```text
yes
```

The aggregation controller copied the rule into `view` within a few seconds. Press Ctrl-C to stop the watch, then run the grader once:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-010/module-01/labs/lab-01
```

You should see `6 passed, 0 failed` and `PROCTOR: PASS`.

Finally remove the lab:

```sh
astrona destroy ats-021-lab-010-01
```
