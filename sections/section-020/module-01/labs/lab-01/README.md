---
estimated_duration: 25m
---

# Lab: Require Mutual TLS And Authorize Callers With Istio

Graded lab for the Istio module. The cluster starts with Istio in `PERMISSIVE` mode and no policy: any caller, with or without a sidecar, can send any request to `scout`. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-020/module-01/labs/lab-01
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-020/module-01/labs/lab-01
astrona destroy ats-021-lab-020-01
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-strict-mtls-required.sh` | `drifter` (no sidecar) gets no HTTP answer from `scout` or `probe`; `shuttle` still reaches `probe` with `200` |
| `validate-scout-allows-shuttle-get.sh` | `shuttle` gets `200` for `GET /` and `GET /version` on `scout` |
| `validate-scout-refuses-other-callers.sh` | `caller` (meshed, `probe` identity) gets `403` on a `GET`, and `shuttle` gets `403` on a `POST` |
| `validate-env-path-denied.sh` | `shuttle` gets `403` on `GET /env` and still `200` on `GET /` |

`caller` is a meshed client in `starfleet` that runs as the `probe` service account. The graders send real requests and retry for about 30 seconds, because the sidecars need a few seconds to receive a new policy. Going back to `PERMISSIVE`, or deleting a policy to make a request work, fails a check.
