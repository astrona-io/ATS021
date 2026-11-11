# Coverage review

The Gatekeeper chart lab now follows an example that carries a fix into the chart template and values, increments chart version, upgrades the release and checks the resulting Pods. Its playground installs the same Helm version used by the lab. Audit scripts now respect the selected container engine when both Docker and Podman are installed.

Practical limits remain:

- Tool-selection discussion and the alternative Gatekeeper registry restriction have no dedicated module lab.
- Signature exercises verify published fixture images with a teaching public key. They do not operate an organization's signing service or manage private signing keys.
- SBOM and vulnerability tasks use live tooling and image-specific evidence, but a passing scan is not proof that an image has no vulnerabilities.
- Audit exercises configure the API server in a kind control-plane container. They test API audit policy and evidence, not host auditd or isolation between tenant kernels.
- Policy exceptions remain limited to the working mechanisms described in the course; the previously unsuccessful Kyverno PolicyException configuration is not claimed as validated practice.

## Runtime choice

All current tasks use kind because their assessed behavior belongs to the Kubernetes API, controllers or cluster workloads. Separate environments keep different service meshes and policy configurations independent. Use QEMU for a future task that needs a separate kernel, VM boot behavior or a host service; none of these changes needs it.

## What verification establishes

The workflow checks registration and preparation order, then runs each selected environment on its own runner. A lab first requires API readiness and an explicit grader FAIL, applies its reference solution, runs all configured graders and tears down. The starting-state check stops at the first intentional rejection; it does not prove that every individual criterion fails initially. Shell errors, missing scripts, timeouts and inconsistent verdicts fail the test.

Playgrounds run bootstrap and readiness checks. A playground with testing/smoke.sh also runs that script. A successful playground start alone does not prove all learner commands. Network downloads, public registries and chart repositories remain external dependencies. Consult the PR's latest workflow for actual runtime results; this review and the generated map are not passing test reports.

## Readings without a module-lab link

These remain visible in the reverse map. Some are supporting concepts or integrated in a section capstone; none is claimed as an independently graded skill merely because it appears in a reading.

- [course-03-choosing-the-right-tool](sections/section-030/module-03/course-03-choosing-the-right-tool.md)
- [course-04-allow-only-one-registry-with-gatekeeper](sections/section-050/module-02/course-04-allow-only-one-registry-with-gatekeeper.md)
