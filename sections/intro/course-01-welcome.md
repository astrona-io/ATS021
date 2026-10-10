# Welcome To The Course

This course trains you for the **Security and Policy Enforcement** part of the **Certified Cloud Native Platform Engineer (CNPE)** exam. That part is 15% of the exam. This page tells you who the course is for, what you can do at the end, which words and example app it uses, and how its pages fit together.

## Who this course is for

You know your way around Kubernetes: namespaces, Deployments, Services, pod labels, `kubectl apply`, `kubectl logs` and `kubectl exec`. You can read a YAML manifest and find a field in it. You do not need to know any of the security tools in this course yet. Each new idea is explained the first time it appears.

## What you can do at the end

The exam is hands-on. You get remote hosts with `kubectl`, a list of tasks and two hours, and the only documentation is the Kubernetes documentation and a short reference page for the tool in each task. The exam touches many tools, but each one only a little. So this course does not ask you to remember words. It teaches the one job the exam asks of each tool, the fields you need for it, and the command that proves your change works. The exam lists five competencies for this part, and each one turns into skills you will practise.

The first competency is **applying RBAC and security controls across platform resources**. You will learn to:

- Give a user or a service account exactly the permissions it needs with `Role`, `ClusterRole` and their bindings.
- Check any permission with `kubectl auth can-i`, also for someone else.
- Make a namespace reject unsafe pods with Pod Security Admission, and make pods pass it with a correct `securityContext`.

The second competency is **configuring secure service-to-service communication**. You will learn to:

- Require mutual TLS (mTLS) between workloads with Istio, and prove that plain-text traffic is refused.
- Allow only named workloads to call a service with an Istio `AuthorizationPolicy`.
- Do the same jobs with Linkerd, the second service mesh the exam may give you.

The third competency is **using policy engines and admission controllers for governance**. You will learn to:

- Write Kyverno policies that validate, change or create objects, and read their policy reports.
- Write a Gatekeeper `ConstraintTemplate` in Rego and apply it with a constraint.
- Write a `ValidatingAdmissionPolicy`, the built-in Kubernetes way to check objects with Common Expression Language (CEL) rules.

The fourth competency is **generating audit trails and enforcing policy compliance**. You will learn to:

- Turn on API server audit logging with an audit policy, and find who did what in the log.
- Collect compliance evidence from Kyverno policy reports, Gatekeeper audit results and API server audit events.

The fifth competency is **integrating security scanning and compliance checks into deployment pipelines**. You will learn to:

- Stop a Tekton pipeline when a compliance check fails, and report the result on every run.
- Make the cluster accept only trusted images: approved registries, no `latest` tag, and images pinned by digest.

## The words this course uses

The pages use Kubernetes' and each tool's own terms, because those are the words you meet in the product, the error messages and the exam. Each term gets a short, plain definition the first time it appears on a page. A few terms come back on almost every page, so here they are up front.

A **pod** runs one copy of an application, and a **namespace** groups pods and other objects inside the cluster. A **service account** is the identity a pod uses. The **API server** is the part of Kubernetes that receives every request to create, read, change or delete an object. Before it stores an object, the API server checks three things, in this order:

| Step | What it checks |
| --- | --- |
| Authentication | Who sent the request: a user or a service account |
| Authorization | Whether that identity may perform this action, for example with RBAC |
| Admission | Whether the object itself is allowed, for example by Pod Security Admission, Kyverno, Gatekeeper or a `ValidatingAdmissionPolicy` |

A **service mesh** is a layer that carries the traffic between workloads. It gives each workload a certificate, encrypts the traffic between them, and can allow or deny each request.

## The example app in your playground

Every playground and lab runs the same small app. The `scout` Service is an HTTP API, and the `probe` Service is an HTTP echo server that some modules add as a second backend. You send your test requests from the `shuttle` pod, a client with `curl`, in the `starfleet` namespace. A second client, `drifter`, runs in the `outpost` namespace. It plays an outside team whose requests a policy often has to block.

Each workload uses its own service account with the same name, because access rules and mesh policies match on the service account. Some modules put the app in their own namespaces, so the pages always tell you which namespace to use. Many playgrounds and labs start with something insecure or broken on purpose. That is the material, not a fault in the course.

## How the course is laid out

The course has five sections. They follow the order a platform team builds security in: first who may use the API, then which traffic is allowed, then which objects are accepted, then what evidence is kept, and last what the delivery pipeline checks.

| Section | What it covers |
| --- | --- |
| 010 | Access Control For Platform Resources |
| 020 | Secure Service-To-Service Communication |
| 030 | Governance With Policy Engines And Admission Control |
| 040 | Audit Trails And Compliance Evidence |
| 050 | Security Checks In The Delivery Pipeline |

Each section has one or more **modules**, and each module teaches one skill. A module brings together four kinds of material:

| What | What it is for | Graded? |
| --- | --- | --- |
| **Reading** | A short landing page, a few chapters that teach one idea each, and a summary | No |
| **Playground** | A small cluster on your own machine, to try everything you read | No |
| **Lab** | A cluster with a problem, a task, and a grader that checks your work | Yes |
| **Capstone** | The last lab in a section, with several tasks at once | Yes |

The best order is simple: read the chapters with the playground open next to them, take each lab when a chapter sends you to it, and finish each section with its capstone. The next part of this page explains how a module's pages guide you through that order.

## How to read a page

A module starts with a **landing page**. It says what the module teaches, what you should know first, and the order of its chapters. At the bottom of the landing page you start the module's playground, and you keep it running while you read.

The chapters (the parts of a module) read like the chapters of a technical book. Each one opens with the problem it solves, explains one idea in connected paragraphs, and closes with what you now know. The hands-on steps sit right in the text: a sentence or two on what to run and why, the command, the real output, and then what that output shows. Run each step in your playground as you reach it. You learn more from one real result than from a page of text.

Every chapter ends with a box of common pitfalls, the mistakes people make most often with what the chapter taught, and how to spot them. Now and then a page also has a tip box with a habit or shortcut you can use again, well beyond that page. The two boxes look like this:

> [!TIP]
> **A tip.** A habit or shortcut you can use again, well beyond this one page.

> [!WARNING]
> **Common pitfalls.** The mistakes people make most often with what you just learned, and how to spot them. Every chapter ends with one.

When a graded lab tests what a chapter taught, that chapter ends with a **Your mission** section. It tells you what the lab asks, then gives every command you need, in order: pause the playground with `astrona stop`, start the lab with `astrona run`, and send your work for grading with `astrona submit`. Solve the lab on your own before you look at its solution. When the lab is done, remove it with `astrona destroy` and start the playground again with `astrona start`, so you can carry on reading where you left off.

The last page of every module is the **Summary**. It sums up what you learned in a few short paragraphs, organised by idea. It also ends the module's hands-on work: the Summary page removes the playground, so your machine is clean before the next module.

One rule holds on every page. Code blocks are exactly what you type or what you will see. Never change a command to make it "look right". If the result is different from the page, that difference is the lesson.
