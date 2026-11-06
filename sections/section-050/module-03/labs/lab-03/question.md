# Question

Solve this question on: `terminal`

## Scenario

The `starfleet` production namespace currently admits any image. The team
needs a signature check that also protects newly labelled production
namespaces. Kyverno 1.19.1 and cosign 3.1.4 are installed, but no signature
policy or verification answer exists.

An image signature binds an image digest to a signing key. The public key
at `/tmp/ats021-050-03-signatures/audit-signing.pub` is a published test key,
not a production trust authority. These are the two candidates, also stored
in the `signature-candidates` ConfigMap in `starfleet`:

| Candidate | Image reference |
| --- | --- |
| scout | `ghcr.io/kyverno/test-verify-image@sha256:b31bfb4d0213f254d361e0079deaaebefa4f82ba7aa76ef82e90b4935ad5b105` |
| probe | `ghcr.io/kyverno/test-verify-image@sha256:74a98f0e4d750c9052f092a7f7a72de7b20f94f176a490088f7a744c76c53ea5` |

The test signatures do not require a transparency log, which records signing
events. Use `--insecure-ignore-tlog` for these fixtures only. The probe fixture
has no valid signature under this key; a malformed signature artifact may
still exist in the registry. Both the terminal and Kyverno need registry
access at run time.

## Tasks

1. **Record verification results.** Check both images with
   `cosign verify --key /tmp/ats021-050-03-signatures/audit-signing.pub` and
   the fixture's transparency-log exception. Create a ConfigMap named
   `signature-audit` in `starfleet`. Set `data.signed-image` to the complete
   image reference that verifies and `data.unsigned-image` to the complete
   reference that has no valid signature. Keep the supplied key and candidate
   ConfigMap unchanged.

2. **Enforce trusted signatures.** Create a `policies.kyverno.io/v1`
   `ImageValidatingPolicy` named `signed-production`. Select namespaces with
   `matchConstraints.namespaceSelector.matchLabels.environment: production`.
   Use the supplied public key, `validationActions: [Deny]` and
   `failurePolicy: Fail`. Match every image in the protected scope, require
   verification and digest references, and cover Pod `CREATE` and `UPDATE`
   requests. Disable background evaluation. Use `insecureIgnoreTlog: true`
   for this test key. Keep the policy ready.

3. **Preserve namespace scope.** Prove with server-side dry runs that both
   production namespaces accept the signed image and refuse the unsigned
   image. Development and unlabelled namespaces must accept both. Keep all
   namespace environment labels unchanged and use service account `scout`,
   which is already present in each namespace.

| Namespace | Starting environment label | Required admission |
| --- | --- | --- |
| `starfleet` | `production` | Signed only |
| `starfleet-canary` | `production` | Signed only |
| `outpost` | `development` | Both images |
| `outpost-unlabelled` | No environment label | Both images |
