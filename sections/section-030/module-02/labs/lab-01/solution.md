# Solution

Solve this lab on `terminal`. The output below comes from a real run of this lab.

Start the lab if it is not running:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-030/module-02/labs/lab-01
```

Keep this command running in a second host terminal. It grades the lab every few seconds and records nothing:

```sh
astrona submit --watch --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-030/module-02/labs/lab-01
```

Use `--watch` until the end, because a plain `astrona submit` finishes the attempt and deletes the lab. Run the plain command once, in the last step.

The watch terminal right after the start shows one check that already passes. `pinned-tags-and-scope` passes because no constraint exists yet, so every pod is accepted. It stays your guard: it fails if your constraint blocks a pinned tag or blocks `outpost`.

## Step 1: Find why the template does not work

Gatekeeper stores a `ConstraintTemplate` even when its Rego does not compile. It then writes the reason to the status of the template. Read it:

```sh
kubectl get constrainttemplate k8sdisallowedtags -o jsonpath='{.status.created}{"\n"}{.status.byPod[0].errors}{"\n"}'
```

You should see:

```text
false
[{"code":"ingest_error","message":"Could not ingest Rego: invalid ConstraintTemplate: 1 error occurred: template:8: rego_parse_error: unexpected eof token\n\t  msg := sprintf(\"container <%v> uses the disallowed tag <%v>\", [container.name, tag])\n\t ..."}]
```

The error message is shortened here. `status.created` is `false`, so the constraint kind `K8sDisallowedTags` does not exist yet. The message `unexpected eof token` means the Rego ends before the `violation` rule is closed: the closing `}` is missing. When you add it, Gatekeeper reports a second error, `undefined function endwith`. The built-in function is `endswith`.

## Step 2: Fix the template

Save this as `constrainttemplate-k8sdisallowedtags.yaml`. It has the closing brace and the function name `endswith`:

```yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8sdisallowedtags
spec:
  crd:
    spec:
      names:
        kind: K8sDisallowedTags
      validation:
        openAPIV3Schema:
          type: object
          properties:
            tags:
              type: array
              items:
                type: string
  targets:
    - target: admission.k8s.gatekeeper.sh
      rego: |
        package k8sdisallowedtags

        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          tag := input.parameters.tags[_]
          endswith(container.image, concat("", [":", tag]))
          msg := sprintf("container <%v> uses the disallowed tag <%v>", [container.name, tag])
        }
```

Apply it:

```sh
kubectl apply -f constrainttemplate-k8sdisallowedtags.yaml
```

You should see `constrainttemplate.templates.gatekeeper.sh/k8sdisallowedtags configured`. Wait about ten seconds, then check the status and the new resource kind:

```sh
kubectl get constrainttemplate k8sdisallowedtags -o jsonpath='{.status.created}{"\n"}'
kubectl api-resources --api-group=constraints.gatekeeper.sh
```

You should see:

```text
true
NAME                SHORTNAMES   APIVERSION                          NAMESPACED   KIND
k8sdisallowedtags                constraints.gatekeeper.sh/v1beta1   false        K8sDisallowedTags
```

The watch terminal now shows the check `template-created` passing.

## Step 3: Deny the latest tag in starfleet

A Constraint of the new kind applies the Rego to the objects it matches. `enforcementAction: deny` makes the Gatekeeper admission webhook refuse a pod that has a violation. Save this as `constraint-no-latest-tag.yaml`:

```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sDisallowedTags
metadata:
  name: no-latest-tag
spec:
  enforcementAction: deny
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
    namespaces: ["starfleet"]
  parameters:
    tags: ["latest"]
```

Apply it:

```sh
kubectl apply -f constraint-no-latest-tag.yaml
```

Wait about ten seconds. Then send a pod with the `latest` tag and a pod with a pinned tag to `starfleet`. The `--dry-run=server` flag runs the full admission but stores nothing:

```sh
kubectl -n starfleet run bad --image=curlimages/curl:latest --dry-run=server
kubectl -n starfleet run good --image=curlimages/curl:8.22.0 --dry-run=server
```

You should see:

```text
Error from server (Forbidden): admission webhook "validation.gatekeeper.sh" denied the request: [no-latest-tag] container <bad> uses the disallowed tag <latest>
pod/good created (server dry run)
```

The watch terminal now shows the checks `latest-denied-in-starfleet` and `pinned-tags-and-scope` passing. Do not set `enforcementAction: dryrun` here: it only records the violation and the pod is still created.

## Step 4: Record the latest tag in outpost

`drifter` in `outpost` uses `curlimages/curl:latest`. A second Constraint with `enforcementAction: dryrun` does not refuse anything. The Gatekeeper audit controller finds the violation and writes it to the status of the constraint. Save this as `constraint-audit-latest-outpost.yaml`:

```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sDisallowedTags
metadata:
  name: audit-latest-outpost
spec:
  enforcementAction: dryrun
  match:
    kinds:
      - apiGroups: [""]
        kinds: ["Pod"]
    namespaces: ["outpost"]
  parameters:
    tags: ["latest"]
```

Apply it:

```sh
kubectl apply -f constraint-audit-latest-outpost.yaml
```

Check that `outpost` still accepts the `latest` tag:

```sh
kubectl -n outpost run other --image=curlimages/curl:latest --dry-run=server
```

You should see `pod/other created (server dry run)`. The audit controller runs about once a minute. Wait until the constraint shows a violation count, then read the results:

```sh
kubectl get k8sdisallowedtags
kubectl get k8sdisallowedtags audit-latest-outpost -o jsonpath='{.status.totalViolations}{"\n"}{.status.violations}{"\n"}'
```

Before the first audit run, `TOTAL-VIOLATIONS` is empty. After it, you should see the count `1` and one violation. The pod name has a random suffix, so yours differs:

```text
1
[{"enforcementAction":"dryrun","group":"","kind":"Pod","message":"container <drifter> uses the disallowed tag <latest>","name":"drifter-6f6fd97b8f-tbrdm","namespace":"outpost","version":"v1"}]
```

Press Ctrl-C to stop the watch, then run the grader once:

```sh
astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-030/module-02/labs/lab-01
```

All four checks pass. The check `audit-lists-drifter` can wait up to three minutes for the audit run. Clean up:

```sh
astrona destroy ats-021-lab-030-02
```
