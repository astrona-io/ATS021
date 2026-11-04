# Summary

Linkerd encrypts every connection between meshed pods with mutual TLS without any setting. Who may connect is decided by a default inbound policy and, for specific ports, by a Server and AuthorizationPolicies.

## What you learned

Linkerd's webhook adds the `linkerd-proxy` native sidecar to pods in a namespace annotated `linkerd.io/inject: enabled`. Each proxy gets a certificate for the identity `<service account>.<namespace>.serviceaccount.identity.linkerd.cluster.local`, which comes only from the service account and the namespace. `linkerd identity` prints it. `linkerd viz edges` shows which connections between meshed workloads are secured, and `linkerd viz tap` shows each request with `tls=true` or `tls=no_tls_from_remote`.

The default inbound policy decides what happens to callers that no Server covers: `all-unauthenticated` (the cluster default) admits everyone, `all-authenticated` admits only meshed identities, the `cluster-` values limit callers to the cluster's networks, and `deny` admits nobody. The annotation `config.linkerd.io/default-inbound-policy` sets it on a namespace or pod, and the proxy reads it when it starts.

A Server (`policy.linkerd.io/v1beta3`) selects a port on pods by `podSelector` and `port`; from then on the port is closed except to AuthorizationPolicies that target it. A MeshTLSAuthentication (`v1alpha1`) names allowed identities, for example by service account in `identityRefs`. An AuthorizationPolicy (`v1alpha1`) connects a `targetRef` with `requiredAuthenticationRefs`. A refused request gets `403` with an empty body. A policy repair starts with its Server target and required authentication reference. Check each backend directly before testing a route. The key facts to remember are these:

- No resource turns on mTLS; meshed pods always use it.
- A Server alone locks its port to everyone.
- MeshTLSAuthentication says who, Server says which port, AuthorizationPolicy connects them.
- Restart workloads after you change the default inbound policy annotation.

A Gateway API HTTPRoute (`gateway.networking.k8s.io/v1`) with a Service parent configures the client's outbound proxy. Its backend weights divide requests between versioned Services, while each backend's Server policy still controls access. The client must be meshed.

Gateway API CRDs are installed separately; this course uses v1.4.0 with Linkerd edge-26.10.1. A large sample with a tolerance gives better evidence of the split than a few replies.

<!-- astrona:playground:destroy -->
