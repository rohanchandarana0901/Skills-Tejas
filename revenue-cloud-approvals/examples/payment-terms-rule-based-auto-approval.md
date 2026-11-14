# Example: Rule-Based Auto-Approval for Approval-Sensitive Field

## Requirement

Auto-approve Specialist approval on resubmission if Approval-Sensitive Field did not change from the previous submitted record. Require manual Specialist approval if Approval-Sensitive Field changed or worsened.

## Approval Workflow

```text
Stage: Commercial Approval
  ↓
Background Step: Evaluate_Approval_Sensitive_Field_Approver_Auto_Approval
  ↓
Target Approval Step: Approval_Sensitive_Field_Approver
```

## Background Step

| Property | Value |
|---|---|
| Step Type | Background Step |
| API Name | `Evaluate_Approval_Sensitive_Field_Approver_Auto_Approval` |
| Action | `<auto-approval-flow-api-name>` |
| Run As | Automated Process User |

## Target Approval Step

| Property | Value |
|---|---|
| Step API Name | `Evaluate_Approval_Sensitive_Field_Approver_Auto_Approval` |
| Start Condition | When another step is marked Complete |
| Custom Logic | Set custom logic for auto-approvals |
| Auto-Approve Step | `varCanAutoApprove` |

## Evaluation Logic

```text
If no previous submission data:
  varCanAutoApprove = false

If current Approval-Sensitive Field = previous Approval-Sensitive Field:
  varCanAutoApprove = true

If current Approval-Sensitive Field is riskier than previous:
  varCanAutoApprove = false

If comparison fails:
  varCanAutoApprove = false
```

## Test Cases

| Scenario | Expected |
|---|---|
| First submission <changed-value> | Manual Specialist approval |
| Resubmission <changed-value> unchanged | Auto-approve Specialist |
| Resubmission <changed-value> → Net 90 | Manual Specialist approval |
| Resubmission <changed-value> → <baseline-value> | Auto-approve if policy allows |
| Previous data missing | Manual Specialist approval |
