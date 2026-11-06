# Solution

Verify both candidates on `terminal`, record the answers, then let Kyverno
check signatures when the Kubernetes application programming interface (API)
server handles Pod requests. An ImageValidatingPolicy declares which images
Kyverno verifies and which signing key it trusts.

| Goal | Evidence |
| --- | --- |
| Establish signer trust | cosign verifies the image digest with the supplied key |
| Record the decision | `signature-audit` ConfigMap in `starfleet` |
| Enforce at admission | Signed accepted and unsigned refused in production |
| Preserve scope | Both candidates accepted outside production |

Keep this command running in a second host terminal. It grades the lab every few seconds and records nothing:

```sh
astrona submit --watch --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-050/module-03/labs/lab-03
```

Use `--watch` until the end, because a plain `astrona submit` finishes the attempt and deletes the lab. Run the plain command once, in the last step.

## Step 1: Verify the candidates

Read the starting labels and candidates, then verify each immutable reference:

```sh
kubectl get namespaces starfleet starfleet-canary outpost outpost-unlabelled -L environment
kubectl -n starfleet get configmap signature-candidates -o yaml
cosign verify --key /tmp/ats021-050-03-signatures/audit-signing.pub --insecure-ignore-tlog ghcr.io/kyverno/test-verify-image@sha256:b31bfb4d0213f254d361e0079deaaebefa4f82ba7aa76ef82e90b4935ad5b105
echo $?
cosign verify --key /tmp/ats021-050-03-signatures/audit-signing.pub --insecure-ignore-tlog ghcr.io/kyverno/test-verify-image@sha256:74a98f0e4d750c9052f092a7f7a72de7b20f94f176a490088f7a744c76c53ea5
echo $?
```

Look for a verified payload whose digest matches the scout reference and a
zero exit code. For probe, look for a nonzero status and a signature
verification failure. A registry connection failure is not evidence that
an image is unsigned. Restore registry access before recording an answer.
No watch checks pass yet because the answer and policy are absent.

The public key verifies the signature; the private key is not needed.
`--insecure-ignore-tlog` skips transparency-log verification for this public
test fixture. It does not skip checking the image digest or signature.

## Step 2: Record the results

A ConfigMap stores non-secret strings. Save this as
`configmap-signature-audit.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: signature-audit
  namespace: starfleet
data:
  signed-image: ghcr.io/kyverno/test-verify-image@sha256:b31bfb4d0213f254d361e0079deaaebefa4f82ba7aa76ef82e90b4935ad5b105
  unsigned-image: ghcr.io/kyverno/test-verify-image@sha256:74a98f0e4d750c9052f092a7f7a72de7b20f94f176a490088f7a744c76c53ea5
```

The `metadata` fields name and scope the object. The two `data` strings
record complete immutable references rather than candidate names. Apply it:

```sh
kubectl apply -f configmap-signature-audit.yaml
```

Then check the result:

```sh
kubectl -n starfleet get configmap signature-audit -o yaml
```

The watch terminal now shows `signature-evidence` passing. It compares the
answers with fresh cosign verification, so registry access is still needed.

## Step 3: Enforce verification in production

Save this as `imagevalidatingpolicy-signed-production.yaml`:

```yaml
apiVersion: policies.kyverno.io/v1
kind: ImageValidatingPolicy
metadata:
  name: signed-production
spec:
  evaluation:
    background:
      enabled: false
  webhookConfiguration:
    timeoutSeconds: 30
  failurePolicy: Fail
  validationActions: [Deny]
  matchConstraints:
    namespaceSelector:
      matchLabels:
        environment: production
    resourceRules:
      - apiGroups: [""]
        apiVersions: [v1]
        operations: [CREATE, UPDATE]
        resources: [pods, pods/ephemeralcontainers]
  matchImageReferences:
    - glob: "*"
  validationConfigurations:
    mutateDigest: false
    verifyDigest: true
    required: true
  attestors:
    - name: auditKey
      cosign:
        key:
          data: |
              -----BEGIN PUBLIC KEY-----
              MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE8nXRh950IZbRj8Ra/N9sbqOPZrfM
              5/KAQN0/KjHcorm/J5yctVd7iEcnessRQjU917hmKO6JWVGHpDguIyakZA==
              -----END PUBLIC KEY-----
        ctlog:
          insecureIgnoreTlog: true
  validations:
    - expression: >-
        (images.containers + images.initContainers + images.ephemeralContainers).map(image,
          verifyImageSignatures(image, [attestors.auditKey])).all(count, count > 0)
      message: Every image must have a signature from the approved key.
```

The namespace selector matches labels, so it protects both production
namespaces and any later namespace with the same label. The resource rules
cover Pod creation, updates and the ephemeral-container subresource used
for debug containers. The image glob selects every image in that scope.

`attestors.auditKey` supplies the trusted public key. The Common Expression
Language (CEL) expression checks regular, init and ephemeral container
images and requires a positive signature count for each. `required` requires
verification, `verifyDigest` requires digests, and `mutateDigest: false`
leaves tag references unchanged so they cannot satisfy that requirement.
`Deny` rejects failed validations; `Fail` refuses requests on evaluation
errors. Background evaluation is disabled because this task tests admission.

Apply it:

```sh
kubectl apply -f imagevalidatingpolicy-signed-production.yaml
```

Then check the result:

```sh
kubectl get imagevalidatingpolicy signed-production -o yaml
kubectl -n kyverno get deployments
```

Wait for `status.conditionStatus.ready` to become true. Read
`status.conditionStatus.conditions` if it stays false. The watch terminal
now shows `production-admission` and `namespace-scope` passing once the
webhook uses the policy. It also keeps `signature-evidence` passing.

## Step 4: Prove admission and scope

Server-side dry runs execute admission without saving Pods or pulling their
images onto a node. Use the existing `scout` service account in each request:

```sh
kubectl -n starfleet run signed-check --image=ghcr.io/kyverno/test-verify-image@sha256:b31bfb4d0213f254d361e0079deaaebefa4f82ba7aa76ef82e90b4935ad5b105 --overrides='{"spec":{"serviceAccountName":"scout"}}' --dry-run=server
kubectl -n starfleet run unsigned-check --image=ghcr.io/kyverno/test-verify-image@sha256:74a98f0e4d750c9052f092a7f7a72de7b20f94f176a490088f7a744c76c53ea5 --overrides='{"spec":{"serviceAccountName":"scout"}}' --dry-run=server
kubectl -n starfleet-canary run signed-check --image=ghcr.io/kyverno/test-verify-image@sha256:b31bfb4d0213f254d361e0079deaaebefa4f82ba7aa76ef82e90b4935ad5b105 --overrides='{"spec":{"serviceAccountName":"scout"}}' --dry-run=server
kubectl -n starfleet-canary run unsigned-check --image=ghcr.io/kyverno/test-verify-image@sha256:74a98f0e4d750c9052f092a7f7a72de7b20f94f176a490088f7a744c76c53ea5 --overrides='{"spec":{"serviceAccountName":"scout"}}' --dry-run=server
kubectl -n outpost run signed-check --image=ghcr.io/kyverno/test-verify-image@sha256:b31bfb4d0213f254d361e0079deaaebefa4f82ba7aa76ef82e90b4935ad5b105 --overrides='{"spec":{"serviceAccountName":"scout"}}' --dry-run=server
kubectl -n outpost run unsigned-check --image=ghcr.io/kyverno/test-verify-image@sha256:74a98f0e4d750c9052f092a7f7a72de7b20f94f176a490088f7a744c76c53ea5 --overrides='{"spec":{"serviceAccountName":"scout"}}' --dry-run=server
kubectl -n outpost-unlabelled run signed-check --image=ghcr.io/kyverno/test-verify-image@sha256:b31bfb4d0213f254d361e0079deaaebefa4f82ba7aa76ef82e90b4935ad5b105 --overrides='{"spec":{"serviceAccountName":"scout"}}' --dry-run=server
kubectl -n outpost-unlabelled run unsigned-check --image=ghcr.io/kyverno/test-verify-image@sha256:74a98f0e4d750c9052f092a7f7a72de7b20f94f176a490088f7a744c76c53ea5 --overrides='{"spec":{"serviceAccountName":"scout"}}' --dry-run=server
```

Look for signed acceptance and an unsigned refusal naming `signed-production`
in both production namespaces. Both requests must succeed in each other
namespace. All three watch checks remain passing; this step makes their
admission evidence visible in your own terminal.

If production accepts the unsigned reference, check `validationActions`,
the namespace selector and policy readiness. If the signed reference fails,
read the API server's response and inspect controller logs:

```sh
kubectl -n kyverno logs deployment/kyverno-admission-controller --all-containers --tail=80
```

A timeout is not a signature verdict. Check registry access and the copied
public key. If either outside namespace refuses an image, correct the
namespace selector rather than changing its labels or disabling enforcement.

## Step 5: Submit

Confirm all three checks pass in the watch terminal. Stop the watch with
Ctrl-C, then finish the attempt once:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-050/module-03/labs/lab-03
```

A pass or fail finishes the attempt and deletes the lab.
