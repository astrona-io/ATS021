---
estimated_duration: 30m
---

# Lab: Admit Only Trusted Images

Graded lab for the image policy module. The cluster starts with Kyverno 1.19.1, its webhooks ready, the namespaces `starfleet` (`environment: development`) and `starfleet-prod` (`environment: production`), and one `ClusterPolicy`, `allowed-registries`, in `Audit` mode. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-050/module-02/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-050/module-02/labs/lab-01
astrona destroy ats-021-lab-050-02
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

The graders create a Deployment with `kubectl create deployment --dry-run=server`, so every Kyverno webhook runs and nothing is stored. The digest in the scripts is the digest of the `podinfo` 6.15.0 image index.

| Script | What it proves |
| --- | --- |
| `validate-registry-enforced.sh` | Images from `docker.io`, from a look-alike host and from a host that only starts with `ghcr.io` are rejected; a `ghcr.io` image is accepted |
| `validate-mutable-tags-rejected.sh` | `:latest` and a missing tag are rejected; a pinned tag in `starfleet` and a digest in `starfleet-prod` are accepted |
| `validate-digest-required-in-production.sh` | A tag without a digest is rejected in `starfleet-prod`; a digest, and a tag with a digest, are accepted; `starfleet` accepts a tag |
| `validate-scope-and-labels-unchanged.sh` | The namespace labels are unchanged, `default` has no `environment` label and accepts `nginx:latest`, and Kyverno runs |

A policy left in `Audit` mode fails the first check. A digest rule that applies to every labelled namespace fails the third check. Removing the namespace label from `starfleet-prod`, or labelling `default`, fails the last check.
