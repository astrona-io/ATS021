# Trace A Compliance Decision Through A Delivery Pipeline

A compliance check matters only if its result controls deployment. Follow the result from the checking Task into the Pipeline condition and then into the actual execution record.

Task failure and a negative compliance result are different paths. A Task may complete successfully while reporting that deployment is not allowed. A when expression can then skip deployment. Inspect both TaskRun status and skipped tasks instead of assuming that a successful PipelineRun means the application was deployed.

A finally task records or cleans up after the run’s main path. It should still provide useful evidence when deployment is skipped or a Task fails. Keep the original decision and report rather than replacing them with a constant passing result.

The execution ServiceAccount limits what a Task can change. Test the allowed deployment action and denied controls separately from the policy logic. Broad cluster rights hide missing permissions without proving the intended boundary.

Run the required passing and failing cases and inspect the resulting workload. The compliance evidence, pipeline decision and live deployment must agree. A manual apply proves neither that the check ran nor that the gate controlled delivery.
