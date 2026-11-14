# Enterprise Troubleshooting Framework

## Approval not starting

Check:

1. Submit action exists on page.
2. Advanced Approvals setup maps Quote to ApprovalWorkflow.
3. `<approval-flow-api-name>` is active.
4. Source record criteria require approval.
5. `ApprovalSubmission` was created.
6. Debug logs show Flow interview start.

## Work item not appearing

Check:

1. Step entry condition is true.
2. Public group exists.
3. User is active.
4. User is in the group.
5. User has Advanced Approvals permission set.
6. Approval Requests component is on Lightning page.
7. Work item exists by SOQL.
8. Smart Approval did not auto-complete it.

## Approval stuck

Running approval processes route record-change events to a dedicated platform event channel, separate from step-completion events, so bulk data loads do not queue ahead of step completions. If a process still stalls after a bulk update, check the orchestration run's paused step and its evaluation flow rather than event backlog.

### Original checklist

Check:

1. Paused and Waiting Interviews.
2. Current stage/step.
3. Stage completion formulas.
4. Step statuses.
5. Rejection formula.
6. Null outputs.
7. Faults in debug logs.

## Smart Approval not firing

Check:

1. Step-level `ActionInput__CanUseSmartApproval = true`.
2. Chain-level Smart Approval enabled.
3. Same chain.
4. Same approver/group membership.
5. Same flow definition version as the original submission.
6. Prior approval was approve.
7. Record not materially modified.
8. Chain configuration unchanged.
9. Query `ApprovalSubmission.IsSmartApprovalRun` (eligibility: `IsEligibleForSmartApproval` on submission and work item; auto-skips: `ApprovalWorkItem.IsAutoReviewed`).

## Missing rejection-condition issue

If any approval step rejects but the business record still routes to the Approved path:

Cause:

```text
One or more rejecting approval steps are missing from the overall rejection formula.
```

Fix:

Add every rejecting step to the overall rejection formula.

## Formula tier issue

If new tier is skipped:

Check tier bounds. Non-top tiers must have an upper bound.

Example:

```text
AND(ApprovalLevel < 4, Level_3_Approver.Status == 'Completed')
AND(ApprovalLevel >= 4, CSuite_Approver.Status == 'Completed')
```

## Deployment issue

Check:

1. Custom fields deployed first.
2. Public groups exist.
3. Approval chains exist.
4. Utility subflows active before orchestration.
5. Main ApprovalWorkflow active last.
6. Draft flows not accidentally promoted.
