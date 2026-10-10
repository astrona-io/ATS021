# Summary

Every request to the API server is authenticated, then authorized, then admitted. RBAC is the authorization step: it sees the identity, the verb, the resource and the namespace, and allows the request only when a rule matches.

## What you learned

A rule lists `apiGroups`, `resources`, `verbs` and optionally `resourceNames`. A `Role` holds rules for one namespace; a `ClusterRole` holds rules that are not tied to a namespace. A `RoleBinding` gives a role's rules to subjects inside its own namespace, even when the role is a ClusterRole. A `ClusterRoleBinding` gives a ClusterRole's rules in every namespace and on cluster-wide resources such as nodes and namespaces. `roleRef` cannot change after a binding is created. RBAC has no deny rules: everything not allowed is forbidden.

Subjects are users, groups and service accounts. Users and groups are only names that the authenticator reports, so binding a team's group is the usual way to give many people the same rights. A service account's user name is `system:serviceaccount:<namespace>:<name>`, and a subject for it carries its namespace.

`kubectl auth can-i` checks one verb on one resource, and `--as` and `--as-group` check it for another identity. `--list` shows every rule that applies. A `Forbidden` error names the user, the verb, the resource, the API group and the namespace, which together are the missing rule. Subresources such as `pods/exec`, `pods/log` and `deployments/scale` are separate entries in a rule, and `can-i` checks them with `--subresource`.

Over-broad grants are found by searching ClusterRoleBindings and RoleBindings for powerful roles such as `cluster-admin`, and by listing every binding that names one identity. Built-in ClusterRoles such as `view` are aggregated: they collect the rules of every ClusterRole that carries their aggregation label, and the API server resets their own content at start. The key facts to remember are these:

- A role says what, a binding says who, and the binding's kind and namespace say where.
- A RoleBinding to a ClusterRole grants the rules in one namespace only.
- `can-i verb resource/name` reads the part after `/` as an object name; use `--subresource` for subresources.
- Extend `view`, `edit` or `admin` with a labelled ClusterRole, never by editing them.

<!-- astrona:playground:destroy -->
