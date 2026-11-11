# Repair The Chart That Generates A Rejected Pod

A live patch can make a workload comply with policy until its next Helm upgrade. Put the repair in the chart's pod template and values, then render and upgrade it. The stored release, chart files and running Pods should describe the same configuration.

This exercise uses the `require-team-label` constraint from this module, with `enforcementAction: deny`. It matches Pods in `starfleet`. Keep that constraint active while changing the workload.

## Create a small chart

The playground installs Helm 4.3.0. Create a directory for a separate `relay` release:

<!-- astrona:playground:renew -->

```sh
export PATH="$HOME/.astrona/bin:$PATH"
mkdir -p ~/resources/relay-chart/templates
```

Save this as `~/resources/relay-chart/Chart.yaml`:

```yaml
apiVersion: v2
name: relay
version: 0.1.0
appVersion: "6.15.0"
```

Save this as `~/resources/relay-chart/values.yaml`:

```yaml
replicaCount: 1
team: starfleet
```

Save this as `~/resources/relay-chart/templates/deployment.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: relay
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: relay
  template:
    metadata:
      labels:
        app: relay
    spec:
      containers:
        - name: relay
          image: ghcr.io/stefanprodan/podinfo:6.15.0
          ports:
            - containerPort: 9898
```

The chart declares a `team` value but the template does not read it. Helm can render and install it, yet Gatekeeper rejects its child Pods:

```sh
helm lint ~/resources/relay-chart
helm template relay ~/resources/relay-chart -n starfleet
helm upgrade --install relay ~/resources/relay-chart -n starfleet
kubectl -n starfleet describe replicaset -l app=relay
```

Read the `FailedCreate` event and the constraint name before editing. Successful rendering proves the YAML can be produced; it does not prove that admission allows the resulting Pods.

## Change the source and release it

Add `team: {{ .Values.team | quote }}` under `spec.template.metadata.labels`, alongside `app: relay`. Keep `spec.selector` unchanged. Set `replicaCount: 2` in `values.yaml` and change the chart version in `Chart.yaml` to `0.2.0`. `appVersion` stays `6.15.0` because the application image did not change.

```sh
helm lint ~/resources/relay-chart
helm template relay ~/resources/relay-chart -n starfleet
helm upgrade relay ~/resources/relay-chart -n starfleet
kubectl -n starfleet rollout status deployment/relay --timeout=120s
kubectl -n starfleet get pods -l app=relay --show-labels
helm get manifest relay -n starfleet
helm list -n starfleet
```

Require two available Pods, each with `team=starfleet`, and release chart `relay-0.2.0`. Compare the rendered pod template with Helm's stored manifest. A label on the Deployment's own metadata does not reach its Pods.

## Distinguish Pod and Deployment rules

A minimum replica count belongs to the Deployment request, because a Pod has no `spec.replicas`. A Rego template that checks both kinds needs separate rules. A Deployment rule can select `input.review.kind.kind == "Deployment"` and test `input.review.object.spec.replicas < 2`; the Pod rule checks `input.review.object.metadata.labels.team`. Include both kinds in the Constraint's match and keep the namespace scope explicit.

Test each rule with an allowed and a denied request. A chart that has the right replica count may still generate Pods with missing labels; satisfying one rule does not establish the other.

## Common pitfalls

> [!WARNING]
> - **Fixing only the live Deployment.** The next Helm upgrade can restore the broken template.
> - **Changing `appVersion` instead of chart `version`.** These record different changes.
> - **Labelling the Deployment alone.** Put workload labels in the pod template.
> - **Checking replicas on Pod admission.** Match the Deployment for that rule.
