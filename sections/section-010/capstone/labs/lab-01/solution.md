# Solution

Solve this lab on `terminal`. Each step ends with `astrona submit`. The `--keep` flag keeps the lab running so you can continue after a failed check. The output below comes from a real run of this lab.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-010/capstone/labs/lab-01
```

## Step 1: Remove cluster-admin from ci-deployer

Find the binding that gives `cluster-admin` to a service account:

```sh
kubectl get clusterrolebindings -o json | jq -r '.items[] | select(.roleRef.name=="cluster-admin") | .metadata.name + "  " + ([.subjects[]? | .kind + ":" + (.namespace // "") + "/" + .name] | join(", "))'
```

You should see:

```text
cluster-admin  Group:/system:masters
kubeadm:cluster-admins  Group:/kubeadm:cluster-admins
orbit-ci-deployer-admin  ServiceAccount:orbit/ci-deployer
```

The first two bindings belong to every kind cluster. Delete only the third, and check that the account lost its rights:

```sh
kubectl delete clusterrolebinding orbit-ci-deployer-admin
kubectl auth can-i get secrets -n orbit --as=system:serviceaccount:orbit:ci-deployer
```

You should see:

```text
clusterrolebinding.rbac.authorization.k8s.io "orbit-ci-deployer-admin" deleted
no
```

## Step 2: Give ci-deployer a Role for Deployments and Services

```sh
kubectl create role workload-manager -n orbit --verb=get,list,watch,create,update,patch,delete --resource=deployments.apps,services
kubectl create rolebinding ci-deployer-workload-manager -n orbit --role=workload-manager --serviceaccount=orbit:ci-deployer
```

You should see:

```text
role.rbac.authorization.k8s.io/workload-manager created
rolebinding.rbac.authorization.k8s.io/ci-deployer-workload-manager created
```

Check one allowed action and two forbidden ones:

```sh
kubectl auth can-i patch deployments.apps -n orbit --as=system:serviceaccount:orbit:ci-deployer
kubectl auth can-i get secrets -n orbit --as=system:serviceaccount:orbit:ci-deployer
kubectl auth can-i list deployments.apps -n default --as=system:serviceaccount:orbit:ci-deployer
```

You should see:

```text
yes
no
no
```

Grade it:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-010/capstone/labs/lab-01 --keep
```

The checks `ci-deployer-manages-orbit`, `ci-deployer-least-privilege` and `cluster-admin-removed` now pass.

## Step 3: Fix the beacon pods before enforcing

A dry run of the label shows which pods would break the level:

```sh
kubectl label --dry-run=server --overwrite namespace orbit pod-security.kubernetes.io/enforce=restricted
```

You should see:

```text
Warning: existing pods in namespace "orbit" violate the new PodSecurity enforce level "restricted:latest"
Warning: beacon-68db69bb4f-6gqnx: allowPrivilegeEscalation != false, unrestricted capabilities, runAsNonRoot != true, seccompProfile
namespace/orbit labeled (server dry run)
```

The warning names the four missing settings. The `beacon` image declares its user by name (`app`), so `runAsNonRoot: true` also needs the numeric `runAsUser: 100`; without it the kubelet refuses to start the container. Patch the pod template:

```sh
kubectl -n orbit patch deployment beacon -p '{"spec":{"template":{"spec":{"securityContext":{"runAsNonRoot":true,"runAsUser":100,"seccompProfile":{"type":"RuntimeDefault"}},"containers":[{"name":"beacon","securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]}}}]}}}}'
kubectl -n orbit rollout status deployment/beacon --timeout=120s
```

You should see:

```text
deployment.apps/beacon patched
deployment "beacon" successfully rolled out
```

(The rollout status command may print `Waiting for deployment "beacon" rollout to finish` lines first.)

## Step 4: Enforce restricted

```sh
kubectl label --overwrite namespace orbit pod-security.kubernetes.io/enforce=restricted
```

The API server prints `namespace/orbit labeled`. If the old `beacon` pod is still shutting down, a warning about it comes first; the pod goes away soon. Then check the pods:

```sh
kubectl -n orbit get pods
```

Run the grader one last time without `--keep`:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-010/capstone/labs/lab-01
```

You should see `5 passed, 0 failed` and `PROCTOR: PASS`. A passed submit removes the lab. If it is still running, remove it:

```sh
astrona destroy ats-021-capstone-010
```
