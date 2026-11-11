# Connect Image Identity To Supply-Chain Evidence

An image tag is a name that can move; a digest identifies image content. Supply-chain evidence must refer to the image actually evaluated and deployed, especially when a pipeline also records an SBOM, vulnerability result or signature verification.

An SBOM lists components. It is evidence to retain, not proof that those components have no vulnerabilities. A scan applies a vulnerability database and policy to that inventory or image. Inspect the scan’s exit behavior as well as its report so a failed check cannot silently continue into deployment.

A signature check adds another decision: whether the selected image has evidence verifiable under the trusted key or identity. Admission policy must enforce the required check on the intended images and workloads. An exclusion that bypasses verification changes the security result even when the Pod starts.

Follow the image reference through the Task parameters, evidence files, policy decision and live workload. Keep the supplied trust material and original reports intact. Distinguish unavailable verification infrastructure from a policy rejection.

Use the accepted and rejected cases specified by the exercise. The retained evidence should explain each decision and identify the exact image involved; successful admission alone does not establish the scan or verification path.
