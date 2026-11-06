---
estimated_duration: 20m
---
# Verify Image Signatures At Admission

Verify two immutable image references with cosign, record the result in a
ConfigMap and enforce the same public key with a Kyverno ImageValidatingPolicy.
Production namespaces require trusted signatures; other namespaces keep
accepting both candidates.

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-050/module-03/labs/lab-03
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-050/module-03/labs/lab-03
astrona destroy ats-021-lab-050-03-03
```

This lab chooses published Kyverno test images and their public test key.
Their digest pins and key match the module's signature exercise. There is
no local registry, private key or signing bootstrap. Terminal cosign 3.1.4
verification confirmed the signed fixture on 2026-11-06 and rejected the
unsigned fixture's malformed signature. Here unsigned means no valid
signature under the supplied key, not necessarily no signature artifact.
The public key is also published in Kyverno 1.19.1's signature test policy.

Both images are admission fixtures, never running workloads. No candidate
image preload is needed for server-side dry runs. All five controller and
initialization images from Kyverno 1.19.1's install manifest are preloaded.
The terminal and admission controller still need registry access at run
time to fetch metadata and signatures. The fixture skips transparency-log
verification; that exception is not a production trust recommendation.

The three graders compare the ConfigMap with fresh cosign verification,
check signed acceptance and unsigned rejection in two production namespaces,
and test both images in development and unlabelled namespaces. A refusal
must name the signature policy; connection failures do not count as proof.
Every check fails on the untouched start state: evidence and policy are
absent. Scope checks require a ready policy before awarding credit.

Author checks: `astrona validate -c sections/section-050/module-03/labs/lab-03`,
YAML parsing, pinned CRD schema validation and shell syntax. Built without
booting on 2026-11-06; live admission and the reference solution are untested.

`astrona validate` could not inspect the configuration because the sandbox
refused its `.maintenance.lock` write. The legacy skill helper expects
`examQuestion` and `guide`; this lab follows sibling `question` and `solution`
keys. YAML parsing, the local Astrona configuration schema, the pinned
Kyverno policy schema, shell and Python syntax, manifest references, unique
environment name and walkthrough/reference-policy parity all passed. The
live-registry verification helper also passed without starting a cluster.
