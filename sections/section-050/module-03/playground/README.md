# SBOM And Scanning Playground

Ungraded environment for inventory generation, vulnerability gates and
public-key signature verification. Installs terminal CLIs and the pinned
Tekton and Kyverno controllers. Preloads workload and Task images. No
scanning Task, Pipeline or signature policy is installed.

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-050/module-03/playground
astrona destroy ats-021-playground-050-03
```

The public key is the published Kyverno keyed-image test key, not a private
credential. Signature tests use server-side dry runs, so the remote test
images need no node preload. `sbom-evidence` uses the kind default StorageClass;
the `evidence-reader` pod also mounts it. Evidence in that PVC disappears
with the cluster; copy it first. Built without booting on 2026-11-06.
