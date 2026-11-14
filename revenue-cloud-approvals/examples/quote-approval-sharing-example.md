# Quote Approval Record Sharing Example

## Requirement

When Quote enters Pending Approval, share the Quote with assigned approvers so they can open the source record and act on the approval request.

## Claude Must Ask First

```text
Do you want me to implement trigger-based or Apex-managed sharing so approvers can access the Quote and related records during approval?
```

## If User Says Yes

Generate:

```text
ApprovalRecordSharingTrigger.trigger
ApprovalRecordSharingHandler.cls
ApprovalRecordSharingService.cls
ApprovalRecordSharingServiceTest.cls
```

## Implementation Notes

- Replace approval status placeholder with org field, such as `<approval-status-field>`.
- Replace approver resolver with actual approver source.
- If approvers need line access, verify child object sharing model.
- If sharing public groups instead of users, use Group Id as `UserOrGroupId`.
- Test as the real approver, not only as System Admin.

## Example Flow

```text
Quote status becomes Pending
  ↓
Trigger calls handler
  ↓
Handler identifies quote ids
  ↓
Service resolves approvers
  ↓
Service inserts QuoteShare rows
  ↓
Approver can open Quote and act on approval request
```
