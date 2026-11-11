# Coverage review

The course has 32 module labs and seven integration capstones. The new focused exercises separate independent jobs that previously shared one lab: granting access, removing excessive access, aggregating roles, authenticating mesh traffic, authorizing requests, validating objects, mutating labels, generating resources, gating a pipeline, reporting its outcome and limiting its identity.

Additional practical gaps now have independent tasks:

| Outcome | Teaching and graded evidence |
| --- | --- |
| Restrict one named scale subresource | RBAC request rules and debugging; a real dry-run scale succeeds for scout while unrelated scaling and template changes fail |
| Stage stronger Pod Security checks | Namespace modes and versions; baseline enforcement with restricted warnings, a warning-free compliant control and an outside namespace control |
| Find a baseline violation across three namespaces | Namespace-level inspection; all three warning labels, live dry-run discovery, exactly one finding label, and the original Pods preserved |
| Repair CEL type and missing-key errors | CEL debugging; valid CREATE and UPDATE requests pass, invalid requests return the intended policy messages, and the outside namespace stays unaffected |
| Scan saved inventories before building a pipeline | Vulnerability exit codes; reports, statuses and counts match independent scans of the same inventories and database |

The baseline-review lab chooses the affected namespace at startup. Its solution discovers the finding from API warnings. Live failure-case checks reject a wrong namespace, blanket findings, a missing warning label and persisted enforcement. A playground procedure test checks the lesson's warn-label and dry-run inspection commands against its own fixtures.

The generated NetworkPolicy exercise also checks empty allow-rule lists and recreation after deletion. It proves Kyverno resource generation, not packet filtering: the default kind network plugin does not enforce NetworkPolicy.

## Remaining limits

Preparation links do not mean every sentence in a reading is independently assessed. The existing Linkerd authorization lab still combines caller policy with the default inbound policy. The audit-logging lab combines API server configuration with investigation of a deletion, and the compliance-evidence lab compares several sources. These are explicit exercises with related evidence, not a claim that every troubleshooting variation has its own lab.

- Signature exercises verify published fixture images with a teaching public key. They do not operate an organization's signing service or manage private signing keys.
- A completed vulnerability scan reports findings for its image, database and filter settings. It is not proof that the image has no vulnerabilities. The standalone scan fixes the database within a lab run; it does not freeze advisory data across future starts.
- Audit exercises configure the API server in a kind control-plane container. They test API audit policy and evidence, not host auditd or isolation between tenant kernels.
- The Pod Security staging lab checks audit labels; it does not claim to inspect stored audit events. Dedicated audit exercises cover that evidence.
- Policy exceptions remain limited to the working mechanisms described in the course; the previously unsuccessful Kyverno PolicyException configuration is not claimed as validated practice.

## Runtime and verification

All current tasks use kind because their assessed behavior belongs to the Kubernetes API, controllers or cluster workloads. Separate environments keep service meshes and policy configurations independent. Use QEMU for a task that needs a separate kernel, VM boot behavior or a host service.

The workflow checks registration and preparation order, then runs each selected environment on its own runner. A lab first requires API readiness and an explicit grader FAIL, applies its reference solution, runs all configured graders and tears down. The starting-state check stops at the first intentional rejection; it does not prove that every individual criterion fails initially. Shell errors, missing scripts, timeouts and inconsistent verdicts fail the test.

Playgrounds run bootstrap and readiness checks. A playground with testing/smoke.sh also runs that script. A successful playground start alone does not prove all learner commands. Network downloads, public registries and chart repositories remain external dependencies. Actual lifecycle results must be reported with the change; this review and the generated map are not passing test reports.

CI also checks quiz registration, answer references, unique question IDs, declared counts and links to earlier readings. Grader regression tests in testing/test-*.py run before each lab lifecycle. The standalone scan tests cover omitted findings, changed package versions, incorrect source identities, wrong counts and forged statuses.

## Readings without a module-lab link

The generated reverse map in [LAB-COVERAGE.md](LAB-COVERAGE.md) lists supporting and capstone-only readings. A listed concept is not claimed as independently assessed without a lab link.

## Reading and practice sequence

Five module lesson pairs now have separate teaching before each lab:

| Module | Reading and practice order |
| --- | --- |
| RBAC | Diagnose an access denial → grant namespace access → limit a named scale subresource → practise scaling rights |
| RBAC | Find excessive grants → remove a broad grant → extend built-in roles → practise aggregation |
| Pod Security | Inspect existing violations → record the baseline inventory → stage enforcement → configure namespace modes |
| Kyverno | Add defaults with mutation → prove label behavior → generate namespace policy → prove creation and recreation |
| Gatekeeper | Read audit results → inventory violations → diagnose template errors → repair compilation |

Each of the seven capstones has its own integration reading immediately before the question. Existing lesson paths and lab identifiers remain valid. Quiz citations follow the extracted teaching, and the generated coverage map includes the new preparation pages.

The sequence validator requires a mapped technical reading between successive labs, including capstones. Questions, summaries and unrelated pages do not count. This update changes teaching order and preparation; lab fixtures, solutions and graders are unchanged.

The extracted named-object reading also corrects the restriction on list and watch: a matching name field selector is required. See the [Kubernetes 1.35 RBAC reference](https://v1-35.docs.kubernetes.io/docs/reference/access-authn-authz/rbac/) for the API behavior.
