# Choose Evidence For A Request And For Current Compliance

An API audit event records a request. A policy report or constraint audit result describes an evaluation of resources. Choose the source that answers the question before collecting identifiers from it.

To attribute a change, use the audit event’s user, verb, object reference, stage and timestamp. The audit policy controls how much request data is retained. Metadata can establish who accessed a Secret without recording its contents, while a suitable body-recording level can preserve the changed fields of a Deployment request.

To describe current compliance, inspect the policy name, rule or constraint, resource identity and result. Read the report’s time context and allow the audit controller to reconcile. Removing a violating resource changes the evidence rather than answering why it violated policy.

Keep evidence collection working while excluding unwanted audit noise. Policy rules are ordered, so an earlier broad match can prevent a later specific rule from taking effect. Check retained events for both the required request and the intentionally omitted class.

Record answers from the supplied environment and keep its original evidence intact. A current clean report does not identify who deleted an earlier resource, and an old admission event does not establish that a workload is compliant now.
