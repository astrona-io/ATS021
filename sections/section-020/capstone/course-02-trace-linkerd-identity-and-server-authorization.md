# Trace Linkerd Identity And Server Authorization

Linkerd gives meshed workloads identities, but automatic mutual TLS does not by itself express which client should reach a server. A Server selects the destination Pods and port; authorization resources connect that server to the permitted authentication requirements.

Start with selection. Confirm that the Server covers the intended workload and actual serving port. Then follow the authorization target and authenticated identity back to the caller’s ServiceAccount and namespace. A typo in any link can make a valid identity look unauthorized.

Use an allowed client and denied controls to distinguish policy scope from connectivity. Verify the target Service still reaches the application before interpreting a denial as a successful security rule. Preserve the mesh components and workload identities throughout the repair.

Where a route also divides traffic, inspect its backend references and use repeated requests to observe both versions. A traffic split and an authorization decision are separate results; a single response cannot prove the distribution or the identity boundary.

Retain the configured policy and verify requests after reconciliation. A temporary direct call to an unmeshed endpoint does not establish that the intended meshed path works.
