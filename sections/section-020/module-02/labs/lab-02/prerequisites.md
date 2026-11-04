# Prerequisites

Allow about 25 minutes. You need `astrona`, a supported container runtime and enough memory for a Kubernetes cluster with Linkerd. The bootstrap installs the pinned `linkerd` command on the terminal and the Gateway API custom resource definitions (CRDs), which add routing resource types to Kubernetes.

Know how to read pod labels, Service selectors and service account identities. A meshed pod has a Linkerd proxy. A Server selects an inbound pod port, a MeshTLSAuthentication names allowed identities, and an AuthorizationPolicy connects them. An HTTPRoute attached to a Service configures forwarding at the client's proxy.

The lab installs its own mesh. Pause another mesh playground before starting it.
