# Prerequisites

Allow about 30 minutes. You need `astrona`, a supported container runtime and enough memory for a Kubernetes cluster with Linkerd. The bootstrap installs the pinned `linkerd` command on the terminal and the Gateway API custom resource definitions (CRDs), which add routing resource types to Kubernetes.

This is an unguided capstone. You should already be able to put a namespace in the Linkerd mesh with the `linkerd.io/inject` annotation and a rollout restart, write a Server for a pod port, connect an AuthorizationPolicy to a MeshTLSAuthentication that names a service account, and attach a weighted HTTPRoute to a Service. Know how to read `kubectl api-resources` to find the API version a cluster serves for a resource kind.

The lab installs its own mesh. Pause another mesh playground before starting it.
