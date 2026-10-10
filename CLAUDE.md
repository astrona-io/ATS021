# Writing style for this repo

All study text here (course pages, lab docs, READMEs, comments in YAML and
scripts) is for people learning a technical subject, often for a
certification exam. Many of them are not native English speakers and have no
university degree.

## Technical documentation in plain English

This is technical documentation. Say exactly what the system does, with the
real technical terms, in clear and simple English. Never hide a concept
behind a metaphor, a made-up name or a vague word: the reader must learn the
words they will meet in the product, the logs and the exam.

Strict guidelines:

1. Use the correct technical term every time (request, response, pod,
   namespace, Service, sidecar proxy, certificate, mTLS, JWT, listener). The
   first time a term appears in a file, define it in one plain sentence that
   says what it is and what it does. Spell out every acronym on first use.
2. No metaphors or analogies in explanations. Not "the communications
   officer", but "the sidecar proxy (Envoy)"; not "a signal", but "a
   request"; not "the planet", but "the namespace".
3. Simple sentences. Target a Flesch-Kincaid Grade Level of 8 or 9 for the
   prose around the terms. Keep sentences direct; split long sentences into
   two. No corporate buzzwords.
4. Use short paragraphs (max 3-4 sentences per paragraph).
5. Use the active voice ("istiod sends the configuration", not "the
   configuration is sent").

## How this applies to course material

- **Know which file you are in.** A module has a short landing page, a few
  deep-dive parts and a summary page. The landing page is a map: goals, what
  to know first, the order of the parts. The real teaching goes in the parts.
  The summary closes the module. A lab
  has a task, a step-by-step solution and a short intro. Keep each file to its
  job. Do not add "Prerequisite: ... Next: ..." navigation lines to pages;
  the landing page and the course outline already give the order.
- **Keep each part short.** One idea per part, about 5 to 8 minutes of
  reading and at most about 8 command blocks, so a learner can finish it with
  the playground in one sitting of about 15 minutes. Split at a natural seam
  where each half ends with something the learner has seen work. Never split
  only to hit a number. When you split, renumber the files, fix every "Part N"
  reference in the module and `astrona.yaml`.
- **Read like a book, not like a web page.** Each part reads as a chapter of
  a technical book. Open with a short paragraph on the problem it solves and
  why it matters. Link each paragraph to the next with a transition sentence.
  Close with a paragraph that sums up what the reader now knows and the
  question still open, before `## Common pitfalls` and the mission. Write
  explanations as prose; keep bullets for real lists (fields, ordered steps,
  options). Use `##` only when the topic changes and `###` only inside a long
  section, never for a single command. Weave hands-on steps into the text:
  one or two sentences on what to run and why, the command, the real output,
  then a sentence or two on what it shows.
- **The module ends with a summary.** The last page of every module is
  `course-0N-summary.md` with the title `# Summary`: a few short prose
  paragraphs on what the reader learned, organised by idea, optionally with
  one short list of key facts. It names no parts, modules, sections or
  chapters, and has no links, lab table, quiz or commands. Its last line is
  `<!-- astrona:playground:destroy -->` on its own line; the platform turns it
  into the step that removes the playground.
- **Every heading gets an intro.** A `##` section that has `###`
  subsections starts with one to three sentences that say what the section
  is about and why it matters, before the first `###`. Never put a `###`
  directly under a `##`.
- **Every module stands on its own.** Never refer to other sections or
  modules: no "see section 040", "as module 3 showed", "you met this in
  section 000", and no links to pages in another module. If the reader needs
  a fact from elsewhere, state the fact directly in one or two sentences.
  This also goes for parts of the same module: never write "Part 2 shows",
  "from Part 1" or "as in Part 3". Say the fact itself ("the commands below
  need the `scout` `DestinationRule` applied"). This includes the summary.
  The landing page does not have a "Where this fits" section.
- **Write words out in full.** Do not use informal short forms in prose:
  write "communications", "configuration", "repository", "administrator",
  "for example" and "that is", never "comms", "config", "repo", "admin",
  "e.g." or "i.e.". Names in code, commands and file paths stay as they are.
- **Exam terms stay.** The product's own names are what the reader must learn
  (for example a resource kind, a field, a command). Use them as they are and
  define each one in plain technical words the first time it appears in a
  file. Spell out acronyms on first use, with a short plain meaning.
- **The space theme is only for examples.** Space appears in two places and
  nowhere else: the names of the example workloads (the Starfleet: `bridge`,
  `scout`, `shuttle`, `probe`, the `starfleet` and `outpost` namespaces) and
  the short scenario that opens a lab task or a practice exercise (for
  example "the `drifter` in `outpost` must keep reaching the probe"). The
  explanation around an example is plain technical text: write "the
  `shuttle` pod sends a request to the `probe` Service", never "the shuttle
  sends a signal to the probe ship". Do not address the reader as an
  astronaut, and do not use space metaphors (communications officer, mission
  control, badge, airlock, guest list, star chart) for Istio or Kubernetes
  concepts. Titles of pages and labs name the technical task ("Require mTLS
  With PeerAuthentication"), not a space story.
- **Show one real example before the rule.** Start with a concrete case the
  reader can run, then give the general rule.
- **Say which part does the work.** Readers often mix up the parts of a system
  that sit close together. Whenever something happens, say which component
  did it.
- **Never change code to fit the style.** Commands, configuration files, field
  names, resource names, log lines and command output stay exactly as they
  are. They were run and checked on a real system. Never make up command
  output. If you shorten it, say that you did.
- **Prose only.** The grade-level and sentence rules apply to explanations.
  They do not apply to code blocks, tables of field names or reference lists
  (those may stay short and dense).
- **Keep the page furniture the same.** Hands-on steps are part of the prose
  (see "Read like a book"), not boxes or headings of their own. A `> [!TIP]` box is
  only for a real tip: advice the reader can reuse beyond this one step (a
  habit, a shortcut, how to spot a problem, an exam habit). Everything else
  is a normal sentence: notes about the current step ("if the log line is
  old, run it again"), background facts, optional extra steps, and plain
  information. Never a command snippet, never two in a row, and most pages
  need zero or one tip. Each part ends with a
  `## Common pitfalls` `> [!WARNING]` block for that part only. Use a Mermaid
  diagram for a flow, an order or a state change, keep it under about 12
  boxes, and follow it with one sentence that says what it shows.
- **Labs come right after the part they practise.** Do not collect all
  graded labs at the end of a module. In `astrona.yaml`, put each lab (its
  `question.md` reading and the `lab` entry) right after the reading part it
  tests. If a part teaches a gradeable skill and no lab covers it, create a
  new lab. That part then ends with a `## Your mission: <lab title>` section:
  one sentence on what the reader can now do, one on what the mission asks,
  then pause the playground (`astrona stop <playground name>`), the
  `astrona run` and `astrona submit` commands, and finally
  `astrona destroy <lab name>` plus `astrona start <playground name>`.
- **Renew the playground before hands-on work.** Every reading part that
  runs commands has `<!-- astrona:playground:renew -->` exactly once, on its
  own line, right before the first hands-on step (the first "Save this as"
  or the first command block), so the playground timer is reset before the
  learner needs the playground. Not on landing pages (they carry
  `<!-- astrona:playground -->`), summary pages (they carry
  `<!-- astrona:playground:destroy -->`) or pages without commands.
- **Mermaid without HTML.** The platform renders Mermaid with HTML labels
  switched off, so `<br/>` and any other HTML tag break the drawing. Rules:
  - One line per box, no `<br/>`, no HTML. Keep the box to the thing's name
    (`"scout-v2"`, `"istiod"`, `"Service: scout"`).
  - Put the logic on the arrows: `E -->|"version: v2"| P2`,
    `I -->|"CDS"| C`, `A -->|"end-user: jason"| B`. Keep edge labels short.
  - Quote every label. Prefer `flowchart TB`; use `LR` only for a short chain.
  - Sequence diagrams: short participant aliases (`participant S as shuttle`)
    and short message text.
  - Anything longer (cluster names, full hostnames) goes in the sentence under
    the diagram.
- **Every course starts with an Introduction.** It lives in `sections/intro/`
  and is the first entry in `astrona.yaml` (`id: module-intro`, title
  "Introduction"). It has exactly these four pages, in this order:
  - `README.md`, `# Introduction`: what the introduction covers and its three
    pages, named in prose (no links), ending with the topic the course starts
    with.
  - `course-01-welcome.md`, `# Welcome To The Course`: who the course is for,
    the exam domain and what the reader can do at the end, the words the
    course uses, the example app, how the course is laid out and how to read
    a page.
  - `course-02-get-your-machine-ready.md`, `# Get Your Machine Ready`: the
    tools to install, the `astrona` commands used every day, and what to do
    when a start goes wrong.
  - `course-03-how-this-course-is-made.md`, `# How This Course Is Made`: how
    content is written and checked, the maintainers, how to report a mistake,
    and the license.
  The Introduction teaches no product content and has no playground, labs or
  summary. Its only links are the repository's contributors page, issues
  page and license.
- **No links to other course files.** A course page (every reading listed in
  `astrona.yaml`, the playground guide `docs/overview.md`, and a lab's
  `question.md` and `solution.md`) never links to or points the reader at
  another page or file of the repository: no links to parts, summaries,
  labs, `question.md`, other modules, sections or the Introduction, and no
  "see `practice.md`" or "open `config.yaml`". The platform shows the pages in
  the order of `astrona.yaml`, so a link only adds a second, often wrong,
  path. Name a thing in plain words when the reader needs it ("the task is on
  the next page"), and state a fact on the page itself instead of sending the
  reader somewhere else. Repository files for authors (the root `README.md`,
  a lab's or playground's `README.md`) may link.
- **No links to outside sources.** Course pages, labs and playground docs do
  not link to or point at outside websites (the one exception is the
  `resources` field of a lab entry in `astrona.yaml`) (official docs, GitHub, blogs,
  RFCs), and they have no "Reference" or "Official docs" lists. Everything the
  reader needs is explained on the page itself. Not affected: addresses the
  reader actually uses in a command or browser (`http://127.0.0.1:9080`,
  `curl https://httpbin.org`), and the Introduction's contributors and
  "report a mistake" links.
- **Configuration goes to a file first.** Whenever the reader should apply
  YAML (course parts, playground docs, labs), use three separate steps:
  1. "Save this as `virtualservice-scout.yaml`:" followed by a plain
     ` ```yaml ` block with only the YAML. No `cat > file <<'EOF'`, no
     `kubectl apply -f - <<EOF`, no shell around it.
  2. "Apply it:" followed by a ` ```sh ` block with only
     `kubectl apply -f virtualservice-scout.yaml`.
  3. "Then check the result:" followed by the check commands, if any.
  The file name says the kind and the object. If a value must come from the
  reader's cluster (an IP address), use a placeholder like `<PARTNER>` in the
  YAML and say how to get the value (`echo $PARTNER`); never put shell
  variables inside YAML. Apply an object the first time its YAML appears; do
  not show it once "to read" and paste it again later. Never tell the reader
  to apply something from the playground's `examples/` folder: they start the
  playground with `astrona run`, so that folder is not on their machine.
- **Helpers have readable names.** Shell helper functions and variables use
  names that say what they do (`check_route`, `count_versions`,
  `$SERVICE_URL`), never single letters.


## About this repo (ATS021 only)

Everything above is general and can be copied to other course repositories. This
section is only true for this one.

### What the student is trying to learn

- **The goal:** pass the **Security and Policy Enforcement** domain of the
  **Certified Cloud Native Platform Engineer (CNPE)** exam. It is 15% of the
  exam.
- **What the exam really tests:** the CNPE is a hands-on exam of 15 to 20
  tasks in 2 hours. The candidate works on remote hosts over `ssh`, with
  `kubectl`, `yq` and `curl`, and the only documentation is
  `kubernetes.io/docs`, the Kubernetes blog and a short "Quick Reference" for
  the tool in each task. The exam covers many tools at a shallow depth:
  breadth is what makes it hard. So every module teaches the one job the exam
  asks of a tool (write the policy, lock down the access, prove the traffic is
  encrypted, block the bad image), the resource kinds and fields to do it, the
  command that shows the result, and where in the tool's reference those
  fields are documented. Every explanation leads to a command the student can
  run, and every change is proved with a real request or a real admission
  decision (an object that was accepted before is now rejected, or the
  reverse).
- **The five exam competencies (curriculum items):**
  1. Configuring Secure Service-to-Service Communication
  2. Applying RBAC and Security Controls Across Platform Resources
  3. Generating Audit Trails and Enforcing Policy Compliance (SBOM,
     Compliance Reports, etc.)
  4. Using Policy Engines and Admission Controllers for Governance
  5. Integrating Security Scanning and Compliance Checks into Deployment
     Pipelines
- **The sections:** the order is the order a platform team builds security,
  inside out: who may do what in the API, which traffic between workloads is
  allowed, which objects the API server accepts at all, what evidence the
  platform keeps, and what the delivery pipeline checks before anything
  reaches the cluster. Curriculum items are therefore not in exam order.

  | Section | Title | Curriculum item |
  | --- | --- | --- |
  | 010 | Access Control For Platform Resources | Applying RBAC and Security Controls Across Platform Resources |
  | 020 | Secure Service-To-Service Communication | Configuring Secure Service-to-Service Communication |
  | 030 | Governance With Policy Engines And Admission Control | Using Policy Engines and Admission Controllers for Governance |
  | 040 | Audit Trails And Compliance Evidence | Generating Audit Trails and Enforcing Policy Compliance |
  | 050 | Security Checks In The Delivery Pipeline | Integrating Security Scanning and Compliance Checks into Deployment Pipelines |

- **The tools:** the CNPE exam lists Argo, Crossplane, Flagger, Flux,
  Gatekeeper, Grafana, Istio, Jaeger, Kyverno, Linkerd, OPA, OpenCost,
  OpenTelemetry, Prometheus and Tekton. This domain uses Istio and Linkerd
  (mutual TLS), Kyverno, Gatekeeper (OPA) and the built-in
  `ValidatingAdmissionPolicy` (admission control), and Tekton (pipelines).
- **Teach only tools on the official CNPE list** (user rule, 2026-10-10):
  Argo, Crossplane, Flagger, Flux, Gatekeeper, Grafana, Istio, Jaeger,
  Kyverno, Linkerd, OPA, OpenCost, OpenTelemetry, Prometheus and Tekton,
  plus built-in Kubernetes (RBAC, Pod Security Admission, `securityContext`,
  `ValidatingAdmissionPolicy`, audit logging, Secrets). Any other tool is a
  waste of the student's time. When a module needs one anyway (cert-manager
  for a mesh, a checker inside a Tekton step), it is hidden plumbing: it is
  installed by the bootstrap or runs as one step image, and the page never
  teaches its commands or flags. Trivy, Syft and cosign are therefore not
  part of this course.
  Where the exam lets the candidate pick between two tools, both are taught:
  **Istio is the primary service mesh** with full depth, and **Linkerd gets
  one compact module**. Kyverno and Gatekeeper each get a full module because
  the exam has separate tasks for each.
- **The versions:** the target is **Kubernetes 1.35**, the version the CNPE
  exam runs. Tool versions, pinned in every `prepare.sh` and bootstrap
  script:

  | Tool | Version |
  | --- | --- |
  | kind | v0.33.0 |
  | Istio (`istioctl`) | 1.31.1 |
  | Linkerd | edge-26.10.1 |
  | Kyverno | 1.19.1 |
  | Gatekeeper | 3.23.1 |
  | cert-manager | 1.21.2 |
  | Tekton Pipelines | 1.17.0 |
  | Tekton CLI (`tkn`) | 0.46.1 |
  | Kyverno CLI step image (plumbing) | `ghcr.io/kyverno/kyverno-cli:v1.19.1` |
  | podinfo | 6.15.0 |
  | go-httpbin | 2.25.0 |

  Do not teach fields, flags or output from other versions without saying
  so. Older tutorials are often wrong for these versions (for example,
  Linkerd's open-source project now publishes only edge releases); check
  every command against the pinned version. cert-manager is plumbing only.
- **The main sources:** the Kubernetes documentation (the only documentation
  the exam allows besides each task's Quick Reference) and each tool's own
  reference pages, listed under "Where to find trusted sources" below.

### Terms, not metaphors

Explanations use Kubernetes' and each tool's own words. Define each one in
plain technical language on first use in a file, for example:

| Term | First-use definition (example wording) |
| --- | --- |
| RBAC | Role-based access control: the Kubernetes API server allows or denies each request by matching the user or service account against the rules of the roles bound to it |
| `Role` / `ClusterRole` | A list of rules (API groups, resources, verbs); a `Role` is valid in one namespace, a `ClusterRole` in all namespaces or for cluster-wide resources |
| `RoleBinding` / `ClusterRoleBinding` | Gives the rules of a role to users, groups or service accounts, in one namespace or in the whole cluster |
| `ServiceAccount` | The identity a pod uses when it calls the Kubernetes API (`system:serviceaccount:<namespace>:<name>`) |
| `kubectl auth can-i` | Asks the API server whether a user or service account may perform one verb on one resource; `--as` checks for someone else |
| Pod Security Admission | A built-in admission controller that rejects or warns about pods that break one of three Pod Security Standards levels (`privileged`, `baseline`, `restricted`), set per namespace with labels |
| `securityContext` | Pod and container fields that set the user, Linux capabilities, privilege escalation, read-only root file system and seccomp profile |
| mTLS | Mutual TLS: both sides of a connection present a certificate, so each side proves its identity and the traffic is encrypted |
| SPIFFE identity | The workload identity in a mesh certificate, written as `spiffe://<trust domain>/ns/<namespace>/sa/<service account>` |
| `PeerAuthentication` | Istio resource that sets whether a workload accepts plain-text traffic (`PERMISSIVE`) or only mTLS (`STRICT`) |
| `AuthorizationPolicy` (Istio) | Istio resource that allows or denies requests to a workload by source identity, namespace, method or path |
| `Server` / `AuthorizationPolicy` / `MeshTLSAuthentication` (Linkerd) | Linkerd resources: a `Server` selects a port on a set of pods, an `AuthorizationPolicy` gives access to it, and a `MeshTLSAuthentication` names the mesh identities that the policy allows |
| Admission controller | Code in the API server that checks, and may change or reject, an object after authentication and authorization and before the object is stored |
| Mutating / validating webhook | An admission controller that the API server calls over HTTPS: a mutating webhook may change the object, a validating webhook may only accept or reject it |
| `ClusterPolicy` / `Policy` (Kyverno) | Kyverno resources with rules that validate, mutate, generate or verify images for matching objects; `validationFailureAction` (`Enforce` or `Audit`) decides whether a failure blocks the request |
| `PolicyReport` / `ClusterPolicyReport` | Kyverno resources that list, per object, which policy rules passed and which failed |
| `ConstraintTemplate` / Constraint (Gatekeeper) | A `ConstraintTemplate` holds a Rego rule and creates a new resource kind; a Constraint of that kind applies the rule to matching objects with parameters |
| Rego | The policy language of Open Policy Agent (OPA); a Gatekeeper rule is a Rego `violation` rule |
| `ValidatingAdmissionPolicy` / `ValidatingAdmissionPolicyBinding` | Built-in Kubernetes resources that validate objects with CEL expressions inside the API server, with no webhook; the binding decides where the policy applies and what happens on failure (`Deny`, `Warn`, `Audit`) |
| CEL | Common Expression Language: a small expression language the API server evaluates, for example `object.spec.replicas <= 5` |
| Audit policy | A file the API server reads that sets, per request type, which audit level to record (`None`, `Metadata`, `Request`, `RequestResponse`) |
| Audit stage | The point in a request when the API server writes an audit event (`RequestReceived`, `ResponseStarted`, `ResponseComplete`, `Panic`) |
| Image tag / digest | A tag (`6.15.0`, `latest`) is a name that can be moved to different image content; a digest (`@sha256:...`) is the hash of the content and always points at the same image |
| Tekton Task result | A small value a Task writes to `$(results.<name>.path)` so later Tasks and `when` expressions can read it |
| `when` expression / `finally` | A `when` expression runs a Pipeline Task only if its condition is true, otherwise the Task is skipped; `finally` Tasks run after all other Tasks, whether they passed or failed |
| Tekton `Task` / `Pipeline` / `PipelineRun` | Tekton resources: a `Task` is a list of steps run in one pod, a `Pipeline` orders tasks, and a `PipelineRun` runs a pipeline once |

The space theme of the example workloads (below) never turns into an
explanation. Write "the `shuttle` pod sends a request to the `scout`
Service", never "the shuttle signals the scout".

### The example workloads

Every section uses the same small app, the Starfleet. Each module puts it in
its own namespaces where it needs a clean start, and the page always names
the namespace. The default namespaces are `starfleet` (the application) and
`outpost` (an outside team).

| Kubernetes name | Image | What it is |
| --- | --- | --- |
| `scout` (Deployment and Service) | `ghcr.io/stefanprodan/podinfo:6.15.0` | HTTP API on port `9898`; the main backend |
| `probe` (Deployment and Service) | `mccutchen/go-httpbin:2.25.0` | HTTP echo server on port `8080`; used where a second backend is needed |
| `shuttle` (Deployment) | `curlimages/curl` | Client pod in `starfleet`; test requests are sent with `kubectl exec deploy/shuttle -- curl ...` |
| `drifter` (Deployment) | `curlimages/curl` | Client pod in `outpost`; the outsider whose requests a policy must block |

Each workload has its own service account with the same name (`scout`,
`probe`, `shuttle`, `drifter`), because RBAC subjects, mesh identities and
authorization policies all match on the service account. Never use the
`default` service account in an example.

### Environment facts the text must respect

- **Pin the cluster in `config.yaml`.** astrona's kind runtime takes
  `runtime.kind.image: kindest/node:v1.35.8` (or `runtime.kind.version`),
  `runtime.kind.nodes.workers`, `featureGates`, `runtimeConfig` and addons
  (`metricsServer`, `certManager`, `gatewayAPI: envoy`, `cni: calico`); see
  `astrona schema`. It does not expose `kubeadmConfigPatches` or
  `extraMounts`, so API server flags must be changed on the node.
- **API server audit logging is configured on the node.** kind's own
  documented method uses `kubeadmConfigPatches` (`apiServer.extraArgs`
  `audit-policy-file` and `audit-log-path`, plus `extraVolumes`) and an
  `extraMounts` entry, all in the kind cluster configuration. astrona does
  not expose that file, so the course does it the exam way instead: open a
  shell on the control plane node container (`docker exec` or
  `podman exec`), write the policy to `/etc/kubernetes/audit/`, edit the
  static pod manifest `/etc/kubernetes/manifests/kube-apiserver.yaml`
  (flags `--audit-policy-file`, `--audit-log-path`, and matching `volumes`
  and `volumeMounts`), and wait for the kubelet to restart the API server.
  The log is then `/var/log/kubernetes/audit/audit.log` on the node. Status:
  **to verify at build** (the node container name astrona uses, and that the
  learner's container engine command works from the playground).
- **Never run Istio and Linkerd in the same playground.** The maintainer's
  Podman machine has 10 GiB and also runs the platform stack. Each
  playground installs only what its module needs.
- **No image registry of its own.** The image policy module checks image
  references (registry, tag, digest) at admission, so it needs no registry
  and no signing. Images are preloaded with `runtime.kind.preloadImages`.
- **Many environments start broken on purpose.** A playground or lab often
  starts with an over-broad `ClusterRoleBinding`, a namespace in `PERMISSIVE`
  mTLS, a privileged pod, or an image with known CVEs. The fault is the
  material. Never "fix" it in the bootstrap.
- **Admission changes are proved by the API server's answer.** A policy is
  proven by applying one object that must be rejected (show the real error
  message) and one that must be accepted. Kyverno and Gatekeeper webhooks
  take a few seconds to become ready after install; bootstrap and graders
  wait for them.
- **Traffic changes are proved by a request.** A mesh policy is proven with
  `kubectl exec` from `shuttle` (allowed) and `drifter` (denied) to the
  `scout` Service. A denied request returns `403` from Istio (`RBAC: access
  denied`); a plain-text request against `STRICT` mTLS fails to connect.
- **Checks inside a pipeline are one step image.** The Tekton compliance
  check runs the Kyverno CLI image as one step against a policy file. It
  needs no outbound internet once the image is preloaded. The page teaches
  the Tekton parts (Task results, `when`, `finally`), not that CLI.
- **The kind node container is `astro-<metadata.name>-control-plane`.**
  For example `astro-ats-021-playground-040-01-control-plane`; reach it with
  `podman exec` or `docker exec`. Verified 2026-10-10.
- **Verified on the pinned versions (2026-10-10):**
  - Istio 1.31.1 installs with `istioctl install --set profile=minimal -y`;
    `istio-proxy` is a native sidecar under `initContainers`. Policy changes
    reach the sidecars within a few seconds; checks right after an apply can
    still show the old result. A DENY rule with only HTTP fields prints a
    warning that it also denies TCP traffic. AuthorizationPolicy `paths` match
    exactly (`/env` does not match `/env/`).
  - Linkerd edge-26.10.1 installs with Gateway API CRDs v1.4.0 first. Policy
    API versions: `Server` `policy.linkerd.io/v1beta3`, `AuthorizationPolicy`
    and `MeshTLSAuthentication` `v1alpha1`. A Server with no
    AuthorizationPolicy denies everyone (`ACCESS POLICY deny`). The
    `config.linkerd.io/default-inbound-policy` annotation takes effect only
    after the workload restarts. A refused request gets `403` with an empty
    body.
  - Kyverno 1.19.1 installs from
    `https://github.com/kyverno/kyverno/releases/download/v1.19.1/install.yaml`
    (`kubectl create`). Every `kyverno.io/v1` ClusterPolicy apply prints a
    deprecation warning (migrate to `policies.kyverno.io` kinds). Rules use
    `validate.failureAction`. PolicyExceptions are off by default
    (`--enablePolicyException=false` on the admission, background and reports
    controllers). Setting the flag to `true` with a JSON patch did not make an
    exception take effect in the playground; **not solved**, so the course
    teaches only that exceptions are off and how to check.
  - `view` already allows EndpointSlices, NetworkPolicies and Ingresses on
    1.35; it does not allow Leases. A ServiceAccount subject without
    `namespace` in a RoleBinding defaults to the binding's namespace.
  - `podinfo`'s image user is the name `app` (ID `100`): `runAsNonRoot: true`
    needs `runAsUser: 100`, or the kubelet refuses with
    `CreateContainerConfigError`.
- **The image tag of go-httpbin has no `v`.** It is
  `mccutchen/go-httpbin:2.25.0`; `v2.25.0` does not exist on Docker Hub.
  Verified 2026-10-10.

### Where things are in this repo

| What | Where |
| --- | --- |
| Course outline the platform reads: every reading page and lab, in order. Never list `solution.md` here | `astrona.yaml` |
| Curriculum blueprint (approved design: sections, modules, objectives, playground contents) | `.astrona/blueprint.yaml` |
| Overview, sections table, how to run things | `README.md` |
| Introduction (see "Every course starts with an Introduction") | `sections/intro/` |
| Section overview and its modules | `sections/section-0N0/README.md` |
| Module reading: landing page, deep-dive parts, closing page | `sections/section-0N0/module-0M/course.md`, `course-0N-*.md` |
| Graded lab: task, walkthrough, setup, grader | `.../labs/lab-01/` (`question.md`, `solution.md`, `prerequisites.md`, `bootstrap/`, `manifests/`, `solution/`, `testing/`, `validation/`) |
| Ungraded sandbox for a module | `.../playground/` (`config.yaml`, `bootstrap/prepare.sh`, `manifests/`, `docs/overview.md`, which is the only learner page) |
| One graded integration lab per section | `sections/section-0N0/capstone/labs/lab-01/` |

A lab folder holds:

| Path | Purpose |
| --- | --- |
| `config.yaml` | Lab definition; `metadata.docs` points at `question.md` and `solution.md` |
| `README.md` | Short intro for authors with `estimated_duration` front matter and the run, submit and destroy commands |
| `prerequisites.md` | What the learner needs before starting |
| `question.md` | The exam-style task. Starts with `# Question` and `Solve this question on: \`terminal\`` |
| `solution.md` | Step-by-step walkthrough with real output |
| `bootstrap/` | Tool install (pinned versions) and the starting state, for example `01-install-kyverno.sh`, `02-seed-workloads.sh` |
| `manifests/` | `lab-start.yaml` (workloads) and the faulty or missing configuration the learner must fix |
| `solution/apply.sh`, `solution/solution.yaml` | Reference end state, applied only by `astrona test` |
| `testing/` | Helpers `astrona test` runs (for example `wait-for-kyverno.sh`) |
| `validation/validate-*.sh` | Behavioural grading, one script per check (for example `validate-privileged-pod-rejected.sh`, `validate-drifter-denied.sh`) |

### Lab metadata in `astrona.yaml`

`astrona.yaml` has a `training:` block (id `ATS021`, domain `Security and
Policy Enforcement`, weight `15`) and one entry per section under `modules:`
(`module-intro`, `module-010`, `module-020` and so on). Each section's
`content` lists, in order: the section `README.md`, then for each module its
landing page, its parts, and right after the part a lab tests, a `Question`
reading (`labs/lab-01/question.md`) followed by the `type: lab` entry; the
module's closing page comes last. The section capstone closes the section.
Playgrounds are not listed: the landing page's `<!-- astrona:playground -->`
marker shows them.

Every `type: lab` entry (module labs and capstones) carries these fields, in
this order:

```yaml
      - type: reading
        title: Question
        path: sections/section-030/module-01/labs/lab-01/question.md
      - type: lab
        title: "Block Privileged Pods With A Kyverno ClusterPolicy Lab"
        path: sections/section-030/module-01/labs/lab-01
        difficulty: beginner
        estimated_duration: 15m
        topic: policy-engines
        task_kind: build
        tags: [kyverno, clusterpolicy, validate-rule, enforce-mode, admission-webhook]
        learning_goals:
          - Write a Kyverno ClusterPolicy that rejects privileged containers in starfleet
          - Prove the policy with one rejected and one accepted Deployment
        resources:
          - name: "Kyverno validate rules"
            url: https://kyverno.io/docs/writing-policies/validate/
```

- `difficulty`: `beginner`, `intermediate` or `advanced`.
- `estimated_duration`: realistic time to solve it, for example `15m`, `30m`, `45m`.
- `topic`: exactly one of `access-control`, `workload-security`,
  `service-mesh`, `policy-engines`, `admission-control`, `audit`,
  `compliance`, `image-policy`, `pipeline-security`.
- `task_kind`: exactly one of `build` (write the configuration from
  scratch), `troubleshooting` (find and fix what is broken) or `migration`
  (move a working setup to another mode or layout). The platform filters labs
  by it, so it is a field of its own, never a tag.
- `tags`: 4 to 8 ids, only from the tag list below. Add a new tag to the list
  first if nothing fits.
- `learning_goals`: 2 or 3 plain sentences, each starting with a verb, saying
  what the learner proves in this lab.
- `resources`: 1 to 4 documentation pages, each with a `name` and a `url`
  that loads. This is the **only** place outside links are allowed: the
  platform shows them as optional further reading next to the lab.

**Tag list** (lower case, hyphens, never synonyms):

- Access control: `rbac`, `role`, `clusterrole`, `rolebinding`,
  `clusterrolebinding`, `serviceaccount`, `auth-can-i`, `least-privilege`,
  `aggregated-clusterrole`
- Workload security: `pod-security-admission`, `pod-security-standards`,
  `security-context`, `capabilities`, `run-as-non-root`, `seccomp`,
  `read-only-root-filesystem`
- Service mesh: `istio`, `linkerd`, `mtls-strict`, `mtls-permissive`,
  `peerauthentication`, `authorizationpolicy`, `spiffe-identity`,
  `linkerd-server`, `meshtlsauthentication`, `cert-manager`
- Policy engines: `kyverno`, `clusterpolicy`, `validate-rule`,
  `mutate-rule`, `generate-rule`, `policyreport`, `enforce-mode`,
  `audit-mode`, `gatekeeper`, `constrainttemplate`, `constraint`, `rego`,
  `gatekeeper-audit`
- Admission control: `admission-webhook`, `validatingadmissionpolicy`,
  `cel`, `policy-exception`
- Audit: `audit-policy`, `audit-log`, `kube-apiserver`, `static-pod`
- Image policy: `image-policy`, `allowed-registries`, `disallow-latest`,
  `image-digest`
- Compliance: `compliance-report`, `policy-audit`
- Pipelines: `tekton`, `tekton-task`, `tekton-pipeline`, `pipelinerun`,
  `task-result`, `when-expression`, `finally-task`, `compliance-gate`

### Running things

```bash
# Playground (ungraded)
astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-010/module-01/playground
astrona destroy ats-021-playground-010-01   # takes metadata.name from config.yaml, not the path

# Lab or capstone (graded against the live cluster)
astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-010/module-01/labs/lab-01
astrona submit -c sections/section-010/module-01/labs/lab-01
astrona destroy ats-021-lab-010-01

# Authors: run a local, uncommitted copy, and prove a lab passes with its reference solution
astrona run -c sections/section-010/module-01/playground
astrona test -c sections/section-010/module-01/labs/lab-01
```

Names: a playground is `ats-021-playground-<section>-<module>`, a module lab
is `ats-021-lab-<section>-<module>` and a capstone is
`ats-021-capstone-<section>`; keep those names. A second lab in a module
takes `ats-021-lab-<section>-<module>-<lab>`, for example
`ats-021-lab-030-02-02`, so two labs never share a name. Lab bootstrap
scripts do not pin a kube context: astrona sets `KUBECONFIG` for the lab, and
`astrona test` runs on a cluster with a different name. Every lab must pass
`astrona validate` and `astrona test`.

Graders check **behaviour**, not just that an object exists: apply the object
that must be rejected and check the API server rejects it, send real traffic
from `shuttle` and `drifter` and check who gets through, read the audit log
for the event that must be there. Many graders also reject the plausible but
wrong fix (binding `cluster-admin` to make a `can-i` check pass, setting
`PERMISSIVE` mTLS to make a request work, switching a policy to `Audit` so
nothing is blocked, labelling a namespace `privileged`, deleting the policy
instead of correcting it). A lab's `question.md` and `solution.md` must match
what its `validation/` scripts actually check.

Test clusters on the maintainer's machine: one at a time. Podman has 10 GiB
and also runs the platform stack; parallel clusters run it out of memory.
Section 020 (service mesh) and sections 040 and 050 (two policy engines, or
Tekton) make the heaviest clusters. Never touch clusters you did not create.

### Where to find trusted sources

Check facts here before writing them down. Prefer these over memory. The
Kubernetes pages are also the documentation the candidate has in the exam.

- **Kubernetes access control and workload security:**
  [RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/),
  [service accounts](https://kubernetes.io/docs/concepts/security/service-accounts/),
  [Pod Security Admission](https://kubernetes.io/docs/concepts/security/pod-security-admission/),
  [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/),
  [security context](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)
- **Kubernetes admission and audit:**
  [admission controllers](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/),
  [dynamic admission control (webhooks)](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/),
  [ValidatingAdmissionPolicy](https://kubernetes.io/docs/reference/access-authn-authz/validating-admission-policy/),
  [CEL in Kubernetes](https://kubernetes.io/docs/reference/using-api/cel/),
  [auditing](https://kubernetes.io/docs/tasks/debug/debug-cluster/audit/)
- **Service mesh:**
  [Istio mutual TLS migration](https://istio.io/latest/docs/tasks/security/authentication/mtls-migration/),
  [PeerAuthentication](https://istio.io/latest/docs/reference/config/security/peer_authentication/),
  [Istio AuthorizationPolicy](https://istio.io/latest/docs/reference/config/security/authorization-policy/),
  [Linkerd automatic mTLS](https://linkerd.io/2/features/automatic-mtls/),
  [Linkerd authorization policy](https://linkerd.io/2/reference/authorization-policy/)
- **Policy engines:**
  [Kyverno policies and rules](https://kyverno.io/docs/writing-policies/),
  [Kyverno policy reports](https://kyverno.io/docs/policy-reports/),
  [Kyverno verify images](https://kyverno.io/docs/writing-policies/verify-images/),
  [Gatekeeper how-to](https://open-policy-agent.github.io/gatekeeper/website/docs/howto/),
  [Gatekeeper audit](https://open-policy-agent.github.io/gatekeeper/website/docs/audit/),
  [Rego policy language](https://www.openpolicyagent.org/docs/latest/policy-language/)
- **Pipelines and image policy:**
  [Tekton Tasks](https://tekton.dev/docs/pipelines/tasks/),
  [Tekton Pipelines](https://tekton.dev/docs/pipelines/pipelines/),
  [Kyverno validate rules](https://kyverno.io/docs/writing-policies/validate/),
  [Gatekeeper library: allowed repos](https://open-policy-agent.github.io/gatekeeper-library/website/validation/allowedrepos/),
  [kind auditing](https://kind.sigs.k8s.io/docs/user/auditing/)
- **The exam itself:**
  [CNPE certification page](https://training.linuxfoundation.org/certification/certified-cloud-native-platform-engineer-cnpe/)
  (domains, weights, competencies),
  [Important Instructions: CNPE](https://docs.linuxfoundation.org/tc-docs/certification/important-instructions-cnpe)
  (exam tools, Kubernetes version, environment) and
  [Resources Allowed](https://docs.linuxfoundation.org/tc-docs/certification/certification-resources-allowed).
  The domain weight (15%) and the five competencies above were checked
  against the certification page on 2026-10-10.

### Skills to use here

The `astrona-course-*` skills do most authoring jobs in this repository: planning
(`domain-plan`), creating the tree (`domain-scaffold`), building modules
(`domain-build`), deep-dive parts (`deep-dive`), labs and playgrounds (`lab`),
lab docs (`lab-docs`), challenges (`create-challenge`), quizzes
(`generate-assessment`) and fact-checking (`review-accuracy`).
