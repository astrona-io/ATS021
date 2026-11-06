# Solution

Solve this lab on `terminal`. After each command, the text says what to look for in its output.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-030/module-02/labs/lab-02
```

Keep this command running in a second host terminal. It grades the lab every few seconds and records nothing:

```sh
astrona submit --watch --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-030/module-02/labs/lab-02
```

Use `--watch` until the end, because a plain `astrona submit` finishes the attempt and deletes the lab. Run the plain command once, in the last step.

The watch terminal right after the start shows all five checks failing. No template and no constraint exist, and the release still runs the faulty chart.

## Step 1: Read the starting state

Helm is in `~/.astrona/bin`. Put that directory on your `PATH` for this shell, then read the release and the Deployment it created:

```sh
export PATH="$HOME/.astrona/bin:$PATH"
helm list -n starfleet
kubectl -n starfleet get deployment probe --show-labels
kubectl -n starfleet get pods -l app.kubernetes.io/instance=probe --show-labels
```

The release list shows one release named `probe` with the status `deployed`, revision `1` and the chart `probe-0.1.0`. The Deployment line shows one replica and the label `team=starfleet` in its `LABELS` column. The pod line shows no `team` label: the chart puts the label on the Deployment only, so a rule on Pods does not see it. Both facts are what the next steps must change.

Look at the template that produces the Deployment:

```sh
cat ~/resources/probe/templates/deployment.yaml
cat ~/resources/probe/values.yaml
```

In the template, `team: {{ .Values.team }}` sits under `metadata.labels` of the Deployment and nowhere under `spec.template.metadata.labels`. In the values, `replicaCount` is `1`.

## Step 2: Write the template with two violation rules

A `ConstraintTemplate` holds the Rego code and declares the parameters a constraint may pass. Each `violation` rule is checked on every matching object, so a rule for Pods must first test the kind of the request. `input.review.kind.kind` is the kind of the object in the admission request. Save this as `constrainttemplate-k8sstarfleetworkloadrules.yaml`:

```yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8sstarfleetworkloadrules
spec:
  crd:
    spec:
      names:
        kind: K8sStarfleetWorkloadRules
      validation:
        openAPIV3Schema:
          type: object
          properties:
            label:
              type: string
            minReplicas:
              type: integer
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8sstarfleetworkloadrules

        violation[{"msg": msg}] {
          input.review.kind.kind == "Pod"
          required := input.parameters.label
          not input.review.object.metadata.labels[required]
          msg := sprintf("pod is missing the required label <%v>", [required])
        }

        violation[{"msg": msg}] {
          input.review.kind.kind == "Deployment"
          minimum := input.parameters.minReplicas
          replicas := input.review.object.spec.replicas
          replicas < minimum
          msg := sprintf("deployment <%v> has %v replicas, the minimum is %v", [input.review.object.metadata.name, replicas, minimum])
        }
```

The first rule stops at its first line for every request that is not a Pod, so it never reports a Deployment. The second rule does the same for Pods. The `not` line is true when the Pod has no label with the name in `input.parameters.label`. The Pod message leaves the name out on purpose: a Pod that a ReplicaSet creates has no name yet at admission time, only a `generateName`.

Apply it:

```sh
kubectl apply -f constrainttemplate-k8sstarfleetworkloadrules.yaml
```

Wait about ten seconds, then check the status and the new resource kind:

```sh
kubectl get constrainttemplate k8sstarfleetworkloadrules -o jsonpath='{.status.created}{"\n"}'
kubectl api-resources --api-group=constraints.gatekeeper.sh
```

The first command prints `true`. If it prints `false`, read `status.byPod[0].errors` of the template: it names the line with the Rego error. The second command lists `k8sstarfleetworkloadrules` with the kind `K8sStarfleetWorkloadRules`. The watch terminal now shows the check `template-created` passing.

## Step 3: Deny both rules in starfleet

One Constraint applies the template to Pods and Deployments in `starfleet`. The `match.kinds` list has one entry per API group: the empty string is the core API group, where Pod lives, and `apps` is the group of Deployment. Save this as `constraint-starfleet-workload-rules.yaml`:

```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sStarfleetWorkloadRules
metadata:
  name: starfleet-workload-rules
spec:
  enforcementAction: deny
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
      - apiGroups: ["apps"]
        kinds: ["Deployment"]
    namespaces: ["starfleet"]
  parameters:
    label: team
    minReplicas: 2
```

Apply it:

```sh
kubectl apply -f constraint-starfleet-workload-rules.yaml
```

Wait about ten seconds. Then send one Pod without the label and one with it to `starfleet`, and one without the label to `outpost`. The `--dry-run=server` flag runs the full admission but stores nothing:

```sh
kubectl -n starfleet run no-team --image=curlimages/curl:8.22.0 --dry-run=server
kubectl -n starfleet run with-team --image=curlimages/curl:8.22.0 --labels=team=starfleet --dry-run=server
kubectl -n outpost run no-team --image=curlimages/curl:8.22.0 --dry-run=server
```

The first command fails with `Error from server (Forbidden)`, the webhook name `validation.gatekeeper.sh`, the constraint name in square brackets and your Pod message. The second and third commands print `created (server dry run)`. Now test the Deployment rule the same way. Save this as `deployment-one-replica.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: one-replica
  namespace: starfleet
spec:
  replicas: 1
  selector:
    matchLabels:
      app: one-replica
  template:
    metadata:
      labels:
        app: one-replica
        team: starfleet
    spec:
      containers:
        - name: test
          image: curlimages/curl:8.22.0
          command: ["sh", "-c", "sleep 3600"]
```

Send it as a server dry run:

```sh
kubectl apply --dry-run=server -f deployment-one-replica.yaml
```

The request is refused with your Deployment message, which names `one-replica`, the value `1` and the minimum `2`. The pod template carries the `team` label, so the replica rule is the only reason. The watch terminal now shows the checks `pod-rule` and `deployment-rule` passing. Do not set `enforcementAction: warn` or `dryrun` here: both admit the object, so the checks keep failing.

## Step 4: See the release fail against the rules

The release still runs revision 1, which was installed before the constraint existed. Admission never looked at it. Upgrade the release from the untouched chart to see what the rules do to it:

```sh
helm upgrade probe ~/resources/probe -n starfleet --wait=watcher --timeout 60s
helm history probe -n starfleet
```

The upgrade fails. Helm prints the admission message from the webhook `validation.gatekeeper.sh` with the constraint name `starfleet-workload-rules`: the Deployment has `1` replicas and the minimum is `2`. The API server refused the update of the Deployment, so nothing in the cluster changed: the old pod keeps running. The history now ends with revision `2` and the status `failed`, and `helm list` reports the release with that status. That is why the check `release-repaired` asks for a `deployed` release: a failed revision at the top of the history is not a running release.

> [!TIP]
> When a Helm upgrade fails with `admission webhook ... denied the request`, the cluster, not Helm, refused the object. Read the constraint name in the brackets and fix the chart; a `helm rollback` only returns to the old, still non-compliant revision.

## Step 5: Repair the chart

Three changes fix the chart. The pod template gets the `team` label, the replica count goes to `2`, and the chart version goes up so the release records a new chart. Replace the contents of `~/resources/probe/templates/deployment.yaml` with this:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}
  labels:
    app.kubernetes.io/instance: {{ .Release.Name }}
    team: {{ .Values.team }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app.kubernetes.io/instance: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app.kubernetes.io/instance: {{ .Release.Name }}
        team: {{ .Values.team }}
    spec:
      serviceAccountName: probe
      containers:
        - name: probe
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          ports:
            - name: http
              containerPort: 8080
          readinessProbe:
            httpGet:
              path: /status/200
              port: http
          resources:
            requests:
              cpu: 10m
              memory: 16Mi
            limits:
              memory: 64Mi
```

The only new line is `team: {{ .Values.team }}` under `spec.template.metadata.labels`. The selector stays as it is: changing `matchLabels` on an existing Deployment is refused by the API server, and the selector does not need the new label. Replace the contents of `~/resources/probe/values.yaml` with this:

```yaml
replicaCount: 2
team: starfleet
image:
  repository: mccutchen/go-httpbin
  tag: "2.25.0"
```

Replace the contents of `~/resources/probe/Chart.yaml` with this:

```yaml
apiVersion: v2
name: probe
description: The probe HTTP echo backend for starfleet
type: application
version: 0.2.0
appVersion: "2.25.0"
```

Lint the chart and render it, then read the two lines that matter:

```sh
helm lint ~/resources/probe
helm template probe ~/resources/probe -n starfleet | grep -n "replicas:\|team:"
```

The lint ends with `0 chart(s) failed`. The rendered manifest shows `replicas: 2` and two `team: starfleet` lines, one in the Deployment labels and one in the pod template.

## Step 6: Upgrade the release

Upgrade the release from the repaired chart. The `--wait=watcher` flag makes Helm wait until the Deployment reports its pods ready, so a pod that admission refuses shows up as a timeout instead of a silent success:

```sh
helm upgrade --install probe ~/resources/probe -n starfleet --wait=watcher --timeout 180s
helm list -n starfleet
kubectl -n starfleet get pods -l app.kubernetes.io/instance=probe --show-labels
```

The upgrade ends without an error. The release list shows `probe` with the status `deployed`, a new revision number and the chart `probe-0.2.0`. The pod list shows two `probe` pods with `1/1` in the `READY` column and `team=starfleet` among their labels. The watch terminal now shows the checks `release-repaired` and `release-pods-ready` passing.

If a pod does not appear, the ReplicaSet could not create it. Read its events:

```sh
kubectl -n starfleet get replicaset -l app.kubernetes.io/instance=probe
kubectl -n starfleet describe replicaset -l app.kubernetes.io/instance=probe | grep -A5 Events
```

A `FailedCreate` event with the Gatekeeper message means the pod template still has no `team` label; fix the template and upgrade again.

Press Ctrl-C to stop the watch, then run the grader once:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-030/module-02/labs/lab-02
```

All five checks pass. Clean up:

```sh
astrona destroy ats-021-lab-030-02-02
```
