---
estimated_duration: 30m
---

# Capstone: Secure Service-To-Service Communication

Graded integration lab for the whole section, on Istio. The mesh starts in `PERMISSIVE` mode with no policy, `beacon` has no sidecar, and `drifter` in `outpost` has a sidecar. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-020/capstone/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-020/capstone/labs/lab-01
astrona destroy ats-021-capstone-020
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-strict-mtls-required.sh` | `drifter-plain` (no sidecar) gets no HTTP answer from `scout` or `probe` |
| `validate-scout-allows-only-shuttle-get.sh` | `shuttle` GET gets `200`; `shuttle` POST, `caller` (`probe` identity) and `drifter` (`outpost` identity) get `403` |
| `validate-probe-only-from-starfleet.sh` | `shuttle` and `caller` get `200` from `probe`; the meshed `drifter` gets `403` |
| `validate-beacon-meshed-and-working.sh` | Every running `beacon` pod has the `istio-proxy` container, and a `GET` from `beacon` to `scout` returns `200` |

`drifter` has a sidecar on purpose: STRICT mTLS alone does not stop it, so `probe` needs an `AuthorizationPolicy`. `beacon` runs as the `shuttle` service account, so it passes the `scout` policy as soon as it has a sidecar. Switching to `PERMISSIVE` fails the plain-text check. The graders retry for about 30 seconds while the sidecars receive new policies.
