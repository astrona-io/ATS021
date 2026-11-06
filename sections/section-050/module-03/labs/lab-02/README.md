---
estimated_duration: 25m
---
# Gate A Tekton Release With A Vulnerability Scan

Add an inventory and scan Task to an ungated release Pipeline. Keep a
CycloneDX SBOM in a retained workspace, export the verdict as a Task
result, and allow deployment only for `pass`.

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-050/module-03/labs/lab-02
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-050/module-03/labs/lab-02
astrona destroy ats-021-lab-050-03-02
```

The grader creates its own PipelineRuns with immutable image references,
checks a real Deployment image change and a skipped deploy Task, compares
saved inventories with fresh registry inventories, then deletes the runs
and rereads both SBOMs through the independent reader pod. The untouched
Pipeline has no check Task, so it cannot pass.

The clean fixture is the `hello-world:linux` index pinned by digest. Both
amd64 and arm64 images have one layer containing only a static C binary,
with no operating system or language package inventory to gain findings.
The failing fixture is Alpine 3.10.3, pinned by index digest; its old
packages retain known vulnerabilities. These are scan fixtures, not service
applications. The target Deployment has zero replicas; deploy means that
the deploy Task successfully patches its image, not that a service becomes
ready. New object names let these resources coexist with the compliance
lab's `release-gate` Pipeline and `scout` Deployment.

The database is downloaded at run time, with metadata saved before scanning
that cache using `--skip-db-update`. Bootstrap checks database connectivity
and prepares a terminal cache; it does not populate the Task's cache. No
database image is required. Kubernetes step, reader and fixture images are
preloaded; remote Trivy inspections still need registry access. The scanner
removes its large database cache after a completed scan while retaining
metadata, report and SBOM, so repeated watch checks do not fill the PVC.

Author checks: `astrona validate -c sections/section-050/module-03/labs/lab-02`, YAML parsing and shell syntax.
Built without booting on 2026-11-06; live behavior remains untested.

YAML parsing, Tekton 1.17.0 release CRD schemas, shell syntax, learner and
reference YAML parity, manifest paths and unique environment names passed.
`astrona validate` could not inspect the lab: the sandbox refused its
`.maintenance.lock` write. The skill's legacy structural helper expects
`examQuestion` and `guide`; this lab follows the siblings' `question` and
`solution` keys. The schema URL in the configuration comment returned 404,
so the full Astrona configuration schema could not be checked independently.
No runtime checks ran.
