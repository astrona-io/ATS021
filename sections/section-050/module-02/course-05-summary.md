# Summary

An admission controller can decide which container images run in the cluster, but it decides on text only. The API server sends the object, including the image string, to a policy webhook before it stores the object. The webhook cannot read the image, so every rule is a rule about the registry, the tag or the digest.

An image reference has a registry, a tag and a digest. A reference without a registry means `docker.io`, and a reference without a tag means `latest`. A tag is a name that the owner of the repository can move to different content. A digest is the SHA-256 hash of the manifest and always names the same content. A reference with both runs the digest.

A Kyverno `ClusterPolicy` writes the three rules as patterns on the `image` field of the container. The pattern `ghcr.io/*` allows one registry. The patterns `*:*` and `!*:latest` reject a missing tag and the `latest` tag. The pattern `*@sha256:*` requires a digest. A `namespaceSelector` in `match` applies a rule to the namespaces with the label `environment: production` only. Kyverno generates the rules for Deployments from the Pod rule, and it marks them with the prefix `autogen-` in the message.

A Gatekeeper `ConstraintTemplate` holds a Rego `violation` rule and creates a new kind. A Constraint of that kind switches the rule on, selects namespaces and gives the allowed registries as parameters. A Constraint that matches `Pod` rejects Pods at once, but it accepts the Deployment request and rejects the Pod later. The reason is in the `FailedCreate` event of the ReplicaSet.

Each policy is proved by the answer of the API server. A server-side dry run shows one rejected and one accepted object without storing anything. The rejection message names the engine through the webhook name (`validate.kyverno.svc-fail` or `validation.gatekeeper.sh`) and the rule or the Constraint that failed.

Key facts:

- `kubectl create deployment ... --dry-run=server` sends the request through all admission webhooks and stores nothing.
- Kyverno `failureAction: Enforce` rejects, and `Audit` only records.
- Gatekeeper `enforcementAction: deny` rejects.
- A digest does not prove that an image is safe. It proves that the content did not change.

<!-- astrona:playground:destroy -->
