---
estimated_duration: 25m
---

# Lab: Repair Linkerd Authorization And Split Service Traffic

The lab starts with no Servers, a default inbound policy of `deny`, and a wrong authentication reference in the second backend's AuthorizationPolicy. Two versioned backend Services are ready. The parent Service selects only v1, so ordinary Kubernetes balancing cannot satisfy the required 80/20 split.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-020/module-02/labs/lab-02
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-020/module-02/labs/lab-02
astrona destroy ats-021-lab-020-02-02
```

## Checks

| Script | What it proves |
| --- | --- |
| `validate-servers.sh` | Each version has a Server selecting its pod port with deny access |
| `validate-authorization.sh` | Both policies require shuttle; shuttle gets 200, meshed caller and unmeshed drifter get 403 from both Services |
| `validate-route.sh` | A Gateway API HTTPRoute attaches to the parent Service and has the required backend weights |
| `validate-observed-split.sh` | Meshed shuttle receives 400 successful replies from live backend pods, with 10–30% from v2 |

The reference solution is `solution/apply.sh`. Authorization checks retry for configuration propagation. The split check takes one fresh sample after successful warm-up requests; a failed request or unknown hostname fails it. The tolerance is ±10 percentage points, rather than an exact request count. All four checks are designed to fail before any changes.

Built without booting on 2026-11-04. Only offline validation was performed; live behavior and the statistical sample still need a runtime test.
