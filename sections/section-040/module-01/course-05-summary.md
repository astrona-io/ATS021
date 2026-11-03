# Summary

Kubernetes audit logging records requests to the application programming interface (API). Its evidence can identify a caller, action, target, time and response status after an object has changed or disappeared. A service account identity identifies the workload credential used for a request; it does not alone identify the human behind that workload.

An audit policy uses the first matching rule to choose the level. `Metadata` keeps request and response bodies out of the event, which suits Secret access. `Request` adds the request body; `RequestResponse` can add both bodies. `None` records nothing. Put sensitive-resource rules before broad filters, and remember that a request with no matching rule is not recorded.

The event's stage describes its point in request handling. `ResponseComplete` includes the result of a finished request. `auditID` groups stage events for one request. The response code distinguishes a successful deletion from an unsuccessful attempt, and timestamps place the action in time.

The API server needs policy and log flags plus matching file mounts. In a static pod setup, the kubelet reads the node's manifest and restarts the container when it changes. A working backup outside the watched directory and direct access to runtime logs let you repair a failed startup even when the API is unavailable.

Audit logs are sensitive evidence. Copy a fresh snapshot for each investigation, check rotated files for older activity, and preserve evidence before destroying a node. Logging cannot recover requests that happened before it was enabled, and it does not replace authorization or a report of current policy compliance.

<!-- astrona:playground:destroy -->
