# Observability and Debug Framework

## Diagnostic layers

1. Source record field values
2. ApprovalSubmission
3. ApprovalWorkItem
4. FlowInterview / paused interviews
5. Debug logs
6. Public Group / GroupMember
7. Advanced Approvals chain setup
8. Flow XML metadata
9. Lightning page components
10. Submit for Approval action configuration

---

## Source record check

```sql
SELECT Id, <approval-level-field>, <approval-sensitive-field>, <approval-status-field>
FROM Quote
WHERE Id = '[QuoteId]'
```

---

## Approval request check

```sql
SELECT Id, Status, IsEligibleForSmartApproval, IsSmartApprovalRun, CreatedDate,
       RelatedRecordId, RelatedRecordObjectName, SubmittedById,
       FlowOrchestrationInstanceId, Comments
FROM ApprovalSubmission
WHERE RelatedRecordId = '[QuoteId]'
ORDER BY CreatedDate DESC
LIMIT 5
```

---

## Work item check

```sql
SELECT Id, Status, AssignedToId, ReviewedById, ReviewedDate, Comments,
       ApprovalChainName, ApprovalConditionName, IsEligibleForSmartApproval,
       IsAutoReviewed, ApprovalSubmissionId
FROM ApprovalWorkItem
WHERE ApprovalSubmission.RelatedRecordId = '[QuoteId]'
ORDER BY CreatedDate DESC
```

### Status values

`ApprovalSubmission.Status` and `ApprovalWorkItem.Status` are two different picklists on two different objects — do not read one as if it explains the other.

| Object | Status values |
|---|---|
| `ApprovalSubmission` | `InProgress`, `Approved`, `Rejected`, `Recalled`, `Suspended`, `Canceled`, `Errored` |
| `ApprovalWorkItem` | `Assigned`, `Approved`, `Rejected`, `Recalled`, `Withdrawn`, `Canceled`, `Errored` |

A submission `InProgress` with no matching `ApprovalWorkItem` row at all (not even one with a stale `Assigned` status) means the work item was never created — check delegation and queue routing below before assuming a data problem.

### Delegation and queue routing

An `ApprovalWorkItem` can look "stuck" because it was never assigned to the user who is looking for it, not because it failed to generate:

```sql
SELECT Id, DelegateId, StartDate, EndDate
FROM ApprovalDelegation
WHERE DelegatorId = '[ExpectedApproverId]'
AND StartDate <= TODAY AND (EndDate = null OR EndDate >= TODAY)
```

An active `ApprovalDelegation` row reroutes the work item to the delegate, who may not be who the requester expects. Also check whether `AssignedToId` on the work item resolves to a `Queue` rather than a `User` — a queue assignment is invisible in a "my approvals" view filtered to the individual user, and the fix is queue membership, not the approval configuration.

---

## Flow interview check

```sql
SELECT Id, InterviewLabel, CurrentElement, Status, StartInterviewUrl,
       FlowVersionView.FlowDefinitionView.ApiName
FROM FlowInterview
WHERE FlowVersionView.FlowDefinitionView.ApiName = '<approval-flow-api-name>'
AND Status IN ('Waiting', 'InProgress')
ORDER BY CreatedDate DESC
```

---

## Group membership check

```sql
SELECT Id, UserOrGroupId, UserOrGroup.Name, UserOrGroup.Type, Group.Name
FROM GroupMember
WHERE Group.Name IN ('Level 1 Approver', 'Level 2 Approver', 'Level 3 Approver')
AND UserOrGroup.Type = 'User'
ORDER BY Group.Name, UserOrGroup.Name
```

---

## Debug log filters

Search for:

```text
FLOW_INTERVIEW_STARTED
FLOW_STAGE_STARTED
FLOW_STEP_STARTED
FLOW_INTERVIEW_EXCEPTION
FLOW_INTERVIEW_FINISHED
<approval-flow-api-name>
```

---

## Recommended custom log object

Do NOT assume `Approval_Action_Log__c` exists in the target org. Ask the user what logging object or mechanism their org uses first.

If the org has no logging object, suggest creating `Approval_Action_Log__c` with these fields:

```text
Approval_Action_Log__c
├── Source_Record_Id__c       (Text)
├── Source_Object__c          (Text)
├── Flow_Api_Name__c          (Text)
├── Stage_Name__c             (Text)
├── Step_Name__c              (Text)
├── Action_Name__c            (Text)
├── Correlation_Id__c         (Text)
├── Status__c                 (Text or Picklist)
├── Error_Message__c          (Long Text Area)
├── Request_Context_JSON__c   (Long Text Area)
├── Response_JSON__c          (Long Text Area)
├── Flow_Interview_Id__c      (Text)
├── Started_At__c             (DateTime)
└── Completed_At__c           (DateTime)
```

Only add a DML Create step for this object in the fault path after the user confirms it exists or agrees to create it.
