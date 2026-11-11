# Separate Istio Transport Identity From Authorization

Mutual TLS authenticates workloads and protects their connection. Authorization decides which authenticated caller may perform an operation. A request can use mutual TLS successfully and still be denied by an authorization policy.

Follow the request from the caller’s ServiceAccount through its proxy to the destination workload. Check the destination’s selected PeerAuthentication policy and the caller’s traffic settings before changing an AuthorizationPolicy. Namespace and workload selectors decide where each policy applies.

Once transport works, inspect the principal, method and path that the authorization rule permits. Test the allowed caller with the allowed operation, then change one dimension at a time for denied controls. A denied client without a working control can hide a transport failure.

Retain a client outside the permitted identity or mesh scope when the exercise calls for one. The difference between its result and the allowed caller establishes the boundary being enforced.

Finish by checking both the policy objects and real requests. Proxy readiness alone does not prove that traffic uses the intended identity or that an over-broad allow rule has been removed.
