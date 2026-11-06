# Solution

Generate inventories on `terminal`, then record the answers in a ConfigMap.
A software bill of materials (SBOM) lists the detected packages; no
vulnerability database is needed for this task.

| Goal | Evidence |
| --- | --- |
| Identify the image | Live Deployment reference and node architecture |
| Keep the inventory | CycloneDX JSON file on the terminal |
| Record package answers | `sbom-audit` ConfigMap in `starfleet` |

Keep this command running in a second host terminal. It grades the lab every few seconds and records nothing:

```sh
astrona submit --watch --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-050/module-03/labs/lab-01
```

Use `--watch` until the end, because a plain `astrona submit` finishes the attempt and deletes the lab. Run the plain command once, in the last step.

## Step 1: Read the live image references

```sh
kubectl -n starfleet get deployments scout probe -o wide
kubectl -n starfleet get deployment scout -o jsonpath='{.spec.template.spec.containers[0].image}'
kubectl -n starfleet get deployment probe -o jsonpath='{.spec.template.spec.containers[0].image}'
kubectl get nodes -L kubernetes.io/arch
```

Read each complete reference, including `@sha256:` and its digest. Use the
architecture in the node label. No check passes yet: the evidence file and
answer ConfigMap do not exist.

## Step 2: Generate the inventories

Replace `<SCOUT-IMAGE>` and `<PROBE-IMAGE>` with the references you just read.
Replace `<ARCH>` with the node's `arm64` or `amd64` value. Trivy fetches the
image from its registry without starting a container.

```sh
mkdir -p /tmp/ats021-050-03-audit
trivy image --image-src remote --platform linux/<ARCH> --format cyclonedx --output /tmp/ats021-050-03-audit/scout.cdx.json <SCOUT-IMAGE>
trivy image --image-src remote --platform linux/<ARCH> --format cyclonedx --output /tmp/ats021-050-03-audit/probe.cdx.json <PROBE-IMAGE>
jq '.metadata.component' /tmp/ats021-050-03-audit/scout.cdx.json
jq '.components | length' /tmp/ats021-050-03-audit/scout.cdx.json
```

Look for the scout image identity and a nonempty component inventory. The
watch terminal now shows `sbom-evidence` passing. The grader compares the
saved image metadata and package inventory with a fresh inventory of the
live image; a JSON file with only a format label cannot pass.

## Step 3: Read and record package answers

```sh
jq -r '.components[] | select(.name == "busybox") | .version' /tmp/ats021-050-03-audit/scout.cdx.json
jq -r '.components[] | select(.name == "bash") | [.name,.version] | @tsv' /tmp/ats021-050-03-audit/scout.cdx.json
jq -r '.components[] | select(.name == "bash") | [.name,.version] | @tsv' /tmp/ats021-050-03-audit/probe.cdx.json
```

Copy the installed busybox version, including its package revision. A bash
row means that Deployment ships bash; no row means that inventory contains
no component with that name. Sort matching Deployment names and join them
with commas if more than one matches.

Save this as `configmap-sbom-audit.yaml`, replacing both placeholders with
your observed answers:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: sbom-audit
  namespace: starfleet
data:
  scout-busybox-version: "<BUSYBOX-VERSION>"
  bash-deployments: "<SORTED-DEPLOYMENT-NAMES>"
```

`metadata` names and scopes the ConfigMap. Its `data` holds two strings:
one package version and the list of Deployment names. Apply it:

```sh
kubectl apply -f configmap-sbom-audit.yaml
```

Then check the result:

```sh
kubectl -n starfleet get configmap sbom-audit -o yaml
```

The watch terminal now shows `package-version` and `package-owners` passing,
along with `sbom-evidence`. If one fails, check that you used installed
package versions, the live image references and the node architecture.
Do not add spaces or a trailing comma to the Deployment list. A registry
error prevents a fresh comparison; restore registry access and let the
watch check again.

## Step 4: Submit

Confirm all three checks pass in the watch terminal. Stop the watch with
Ctrl-C, then finish the attempt once:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-050/module-03/labs/lab-01
```

A pass or fail finishes the attempt and deletes the lab.
