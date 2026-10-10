# How This Course Is Made

You will trust a course more when you know how it is built. This page tells you how the content is written and checked, who is behind it, and how you can help make it better.

## How the content is written

The course targets fixed versions. It aims at **Kubernetes 1.35**, the version the CNPE exam runs, and every tool is pinned to one version, for example **Kyverno 1.19.1**, **Gatekeeper 3.23.1** and **Istio 1.31.1**. When a page says how a tool behaves, it means that version. Each playground installs exactly that version for you.

Facts come from real sources. They are checked against the official Kubernetes documentation, the same documentation you may open in the exam, and against the reference pages of each tool. Each page then explains everything you need on the page itself, so you never have to leave the course to look something up.

Command output is real, too. When a page shows output, it comes from a real run. If the output is shortened, the page says so. If there was no real run to copy from, the page describes the result in words instead of making up output. Scan results are a special case: the list of known vulnerabilities changes every day, so the pages teach you how to read and filter a scan, not an exact count.

The same care goes into the graded labs, because their graders check behaviour. A grader tries to create the object your policy must reject, sends real requests between workloads, and reads the audit log and the policy reports. Many graders also reject the change that only hides the problem, such as giving an account full cluster rights, switching mTLS back to plain text, or setting a policy to only report instead of block. Each lab also has a reference solution that is run against its own grader, so the grader is known to accept a correct answer.

The pages are written in plain English, for people who are not native English speakers and have no university degree. Words are written out in full, and each technical term gets a short, plain definition the first time it appears. The pages use the real technical terms, not metaphors, because those are the words you meet in the product, the error messages and the exam.

Finally, large parts of this course are drafted and edited with the help of AI tools. A maintainer reviews every change before it is published, and the technical checks above apply to all content, however it was written.

## Maintainers

A small group of people builds and looks after the course. The core maintainer is **Paris Nakita Kejser** ([@parisnakitakejser](https://github.com/parisnakitakejser)).

Many others have helped along the way. Every person who has changed the course is listed on the GitHub contributors page:
[github.com/astrona-io/ATS021/graphs/contributors](https://github.com/astrona-io/ATS021/graphs/contributors)

## Found a mistake? Report it

Even with these checks, mistakes slip through. If a command fails, a page says something wrong, or a lab grades a correct answer as wrong, please tell us. Every report makes the course better for the next learner. A good report takes four steps:

1. Open a new issue on GitHub: [github.com/astrona-io/ATS021/issues](https://github.com/astrona-io/ATS021/issues).
2. Say which page or lab it is (the file path is the easiest, for example `sections/section-010/module-01/labs/lab-01`).
3. Paste the command you ran and what you saw. Leave out passwords, tokens, private keys, signing keys or anything else private. An audit log or a secret from a real cluster can hold private data, so never paste one from a real cluster.
4. Say what you expected to happen instead.

Want to fix it yourself? Pull requests are welcome on the same repository.

## License

The course is published under the [Apache License 2.0](https://github.com/astrona-io/ATS021/blob/main/LICENSE). You are welcome to use it, share it and build on it under the terms of that license.
