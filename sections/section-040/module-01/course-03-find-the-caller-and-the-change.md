# Find The Caller And The Change

The `probe` Deployment is present now, but a workload may have deleted and recreated it. Its current state cannot identify that earlier caller. An **audit event**, a record of a request to the Kubernetes application programming interface (API), can show the action, identity, timestamp and result.

The commands below need audit logging enabled with Secret requests at `Metadata` and Deployment changes at `RequestResponse`. They copy the current log to your machine and use `jq`, a command for selecting fields from JavaScript Object Notation (JSON) documents. The log holds one JSON document per line.

## Produce one known action

Pause the scheduled CronJob before starting a sample Job. A CronJob creates Jobs on a schedule; a Job runs a task to completion. `suspend: true` stops future scheduled Jobs but does not stop a Job already running. Let any active scheduled Job finish before creating the sample, so two Jobs do not delete `probe` at the same time.

<!-- astrona:playground:renew -->

```sh
kubectl -n outpost patch cronjob deck-cleaner --type=merge -p '{"spec":{"suspend":true}}'
```

You should see something like:

```text
cronjob.batch/deck-cleaner patched
```

Trigger the prepared task once and read its result:

```sh
kubectl -n outpost create job audit-sample --from=cronjob/deck-cleaner
kubectl -n outpost wait --for=condition=complete job/audit-sample --timeout=90s
kubectl -n outpost logs job/audit-sample
```

You should see something like:

```text
job.batch/audit-sample created
job.batch/audit-sample condition met
read secret: 200
delete probe: 200
create probe: 201
```

The three codes show a successful Secret read (`200`), Deployment deletion (`200`) and creation (`201`). The Job calls the API server as `system:serviceaccount:outpost:deck-cleaner`, the service account identity of its pod. The namespace in that identity is the caller's namespace, not the namespace of the object it changes.

Copy a snapshot of the log:

```sh
export CONTROL_PLANE=astro-ats-021-playground-040-01-control-plane
podman cp "$CONTROL_PLANE":/var/log/kubernetes/audit/audit.log audit.log
```

This file does not update as new events arrive. Copy it again after another action. Copying can also catch an incomplete last line while the API server writes; if `jq` reports a parse error, take another copy after the request has finished.

## Find a successful deletion

The event's `verb` is the Kubernetes API action, such as `get`, `create` or `delete`. `objectRef` identifies the resource, namespace and name. `responseStatus.code` is the Hypertext Transfer Protocol (HTTP) response code, which shows whether the request succeeded.

Select the most recent completed, successful deletion of `probe`:

```sh
jq -sr '[.[] | select(.stage == "ResponseComplete" and .verb == "delete" and .objectRef.namespace == "starfleet" and .objectRef.resource == "deployments" and .objectRef.name == "probe" and .responseStatus.code == 200)] | last | [.stageTimestamp, .user.username, .verb, .objectRef.name, .responseStatus.code] | @tsv' audit.log
```

You should see something like:

```text
2026-10-12T16:54:55.303258Z	system:serviceaccount:outpost:deck-cleaner	delete	probe	200
```

`-s` reads the events into an array, `select` filters them, and `last` chooses the final matching event in this snapshot. `-r` prints raw text. `@tsv` separates the chosen fields with tabs. The columns are completion time, caller, verb, object name and response code; the timestamp will differ in your playground.

The filter includes `ResponseComplete`, the stage after the response has finished sending. A `RequestReceived` event alone would not prove the result. The `200` filter also excludes a failed attempt to delete an object that was already gone, which returns `404`.

Inspect the same request's identifying fields:

```sh
jq -s '[.[] | select(.stage == "ResponseComplete" and .verb == "delete" and .objectRef.namespace == "starfleet" and .objectRef.name == "probe" and .responseStatus.code == 200)] | last | {auditID, requestReceivedTimestamp, stageTimestamp, user: .user.username, sourceIPs, userAgent}' audit.log
```

You should see something like:

```text
{
  "auditID": "7567502b-d337-4f57-b2e5-179bc281a714",
  "requestReceivedTimestamp": "2026-10-12T16:54:55.298971Z",
  "stageTimestamp": "2026-10-12T16:54:55.303258Z",
  "user": "system:serviceaccount:outpost:deck-cleaner",
  "sourceIPs": [
    "10.244.0.16"
  ],
  "userAgent": "curl/8.22.0"
}
```

`auditID` identifies this request, and stage events for it share that value. `requestReceivedTimestamp` is when the server received it; `stageTimestamp` is when this stage occurred. The timestamps use Coordinated Universal Time (UTC), shown by `Z`. `sourceIPs` and `userAgent` add context, but the authenticated `user.username` is the identity the API server used.

A service account identity points to a workload credential. It does not by itself identify the human who changed that workload. If impersonation is used, inspect `impersonatedUser` as well as the original `user` before attributing the action.

## Prove the policy kept the right detail

A **Secret** stores sensitive data. The policy puts its requests at `Metadata`, which excludes request and response bodies. Check that claim against the real read:

```sh
jq -s '[.[] | select(.stage == "ResponseComplete" and .verb == "get" and .objectRef.resource == "secrets" and .objectRef.name == "scout-db-credentials")] | last | {level, stage, user: .user.username, code: .responseStatus.code, requestBody: has("requestObject"), responseBody: has("responseObject")}' audit.log
```

You should see something like:

```text
{
  "level": "Metadata",
  "stage": "ResponseComplete",
  "user": "system:serviceaccount:outpost:deck-cleaner",
  "code": 200,
  "requestBody": false,
  "responseBody": false
}
```

The read succeeded, but `has("requestObject")` and `has("responseObject")` both return `false`. You can prove who accessed the named Secret without copying its password into the log.

Compare the successful Deployment creation:

```sh
jq -s '[.[] | select(.stage == "ResponseComplete" and .verb == "create" and .objectRef.resource == "deployments" and .objectRef.name == "probe" and .user.username == "system:serviceaccount:outpost:deck-cleaner" and .responseStatus.code == 201)] | last | {level, stage, code: .responseStatus.code, image: .requestObject.spec.template.spec.containers[0].image, storedName: .responseObject.metadata.name}' audit.log
```

You should see something like:

```text
{
  "level": "RequestResponse",
  "stage": "ResponseComplete",
  "code": 201,
  "image": "mccutchen/go-httpbin:2.25.0",
  "storedName": "probe"
}
```

At `RequestResponse`, the event contains the submitted image and the stored object's name. `201` means the create succeeded. Not every request has a body: a GET has no request object, and some response types do not produce an audited response object. Choose fields that fit the request instead of assuming every high-detail event contains both bodies.

The pod reads made while retrieving the Job logs should match the generic `None` rule. Check that the snapshot contains no recorded pod GET requests:

```sh
jq -s '[.[] | select(.verb == "get" and .objectRef.resource == "pods")] | length' audit.log
```

You should see:

```text
0
```

This checks the read filter against requests you know occurred. The first matching policy rule determines the level. The Secret read matched the first rule before the generic read filter. The Deployment creation matched the change rule before the final metadata rule. A missing event could mean a `None` rule, an omitted stage, a rotated file or activity before logging started; it does not prove no request occurred.

You can now turn an audit snapshot into a concrete answer: which credential deleted an object, when the request completed, and whether it succeeded. Comparing Secret and Deployment events also proves that the policy recorded the intended detail.

## Common pitfalls

> [!WARNING]
> - **Counting each stage as a separate action.** Group by `auditID` or select one stage before counting requests.
> - **Treating a delete attempt as a successful deletion.** Inspect `responseStatus.code`; `404` means the target was not found.
> - **Confusing caller and target namespaces.** `outpost` is in the service account identity; `starfleet` is in `objectRef.namespace`.
> - **Searching a stale snapshot.** Copy the log again after new activity, and check rotated files for older events.
> - **Expecting a Secret body at `Metadata`.** That level deliberately excludes both bodies.
