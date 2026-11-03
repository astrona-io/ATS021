# Audit Trails And Compliance Evidence

A platform needs evidence of both its changes and its current policy results. Kubernetes audit events record who called the application programming interface (API), what they requested and how the server responded. Policy engines produce a different kind of evidence: results that show which existing objects meet their rules.

Audit logging starts with a policy that chooses the detail for each request. Secret access should record the caller and target without recording sensitive bodies. Deployment changes can include request and response bodies when those details are needed and the log is protected.

This section covers configuring API server audit logging, finding the identity behind a change, and recovering a failed static pod restart. It also covers the roles of policy reports and audit results in answering compliance questions. Request history answers what happened; a current report answers what breaks a policy now.

### Section Capstone Challenge
*   **Comprehensive Challenge:** Audit Trails And Compliance Evidence Capstone — `sections/section-040/capstone/labs/lab-01`
    ```bash
    astrona run --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-040/capstone/labs/lab-01
    astrona submit --git ssh://git@github.com/astrona-io/ATS021.git -c sections/section-040/capstone/labs/lab-01
    ```
*   **Hands-on Objective:** Turn on API server audit logging with a given policy, then answer an auditor: which identity deleted a Deployment, which Deployments fail a Kyverno policy and which violate a Gatekeeper constraint. The grader checks the audit log settings and compares the answers with the live evidence.
