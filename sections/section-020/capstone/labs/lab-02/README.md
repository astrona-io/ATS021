---
estimated_duration: 30m
---

# Capstone: Secure Service-To-Service Communication With Linkerd

Second graded integration lab for the section, on Linkerd. The `starfleet` namespace starts outside the mesh, no Server or HTTPRoute exists, and the `MeshTLSAuthentication` names the wrong service account. The task is in `question.md`; the walkthrough is in `solution.md`.

## Run it

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-020/capstone/labs/lab-02
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-020/capstone/labs/lab-02
astrona destroy ats-021-capstone-020-02
```

Authors run the local copy with `astrona run -c <lab>` and prove the reference solution with `astrona test -c <lab>`.

## Checks

| Script | What it proves |
| --- | --- |
| `validate-namespace-meshed.sh` | `starfleet` carries `linkerd.io/inject=enabled` and every running pod of the four Deployments has the `linkerd-proxy` container |
| `validate-server-protects-scout.sh` | The only Server, `scout-http`, selects `app: scout` on the pod port `http` with `HTTP/1` and `accessPolicy: deny` |
| `validate-only-shuttle-allowed.sh` | `scout-allow-shuttle` is the only AuthorizationPolicy, it requires `scout-callers`, which names only the `shuttle` ServiceAccount; `shuttle` gets `200` and `caller` gets `403` from both versions |
| `validate-route-attached.sh` | `scout-split` has the core Service `scout:80` as parent, backends `scout-v1:80` weight `75` and `scout-v2:80` weight `25`, and Linkerd reports `Accepted=True` and `ResolvedRefs=True` |
| `validate-observed-split.sh` | 400 requests from `shuttle` to `scout` all succeed and 60 to 140 of them reach v2 |

The graders send real requests from the allowed and the denied client and read the route status that the Linkerd policy controller writes. They retry for about 30 seconds while the proxies receive new policy. Built on 2026-11-06 without booting a cluster; the layout and the bootstrap come from the module-02 labs, which were tested.
