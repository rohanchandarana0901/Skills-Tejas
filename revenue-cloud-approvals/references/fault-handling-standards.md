# Fault Handling and Resilience Standards

## ⛔ Critical metadata constraint

`FlowStageStep` (stage steps inside `orchestratedStages` of an ApprovalWorkflow) does **NOT** support `<faultConnector>`. The Metadata API rejects fault connectors on `stepApproval` and `stepBackground` stage steps. Never generate fault connectors at the stage-step level.

Never add an unreachable "Fault Handler" stage to an ApprovalWorkflow. An orphan stage (no inbound connector) forces Flow Builder to render the flow in free-form canvas, where stage steps are NOT visible — the approval process appears to have no steps even though the metadata is correct.

## Standard fault architecture

Fault handling lives **inside the autolaunched utility subflow** that a `stepBackground` calls. Regular flow elements there (Get Records, Update Records, Action, Subflow) support `<faultConnector>` normally.

Fault paths must be **org-neutral** — never hardcode `Approval_Action_Log__c` or any custom logging object; it may not exist in the target org.

```text
AutoLaunchedFlow (called by a stepBackground stage step)
  Get Records / Update Records / Action element
    ↓ faultConnector (supported here — NOT on stage steps)
  Update source record status = Approval Error
    ↓
  Store {!$Flow.FaultMessage} in a text variable
    ↓
  Choose notification mechanism available in the org:
    Option A: Send email alert to submitter/admin
    Option B: Create a platform event
    Option C: If the org has a custom logging object, create a record — ask the user which one
              If no object exists, suggest creating Approval_Action_Log__c (see observability-debug-framework.md)
```

When building the error handler subflow, use the minimal pattern above by default; ask which logging mechanism the org uses only if the user wants logging beyond it. If none exists, suggest creating `Approval_Action_Log__c`. Only add a DML Create step after the user confirms the object exists or agrees to create it.

## Error Handler Inputs

Recommended inputs:

| Input | Purpose |
|---|---|
| SourceRecordId | Quote/order/custom record Id |
| SourceObjectApiName | Object API name |
| FlowApiName | Flow name |
| StageName | Stage where error occurred |
| StepName | Step/action where error occurred |
| ErrorMessage | Error details |
| CorrelationId | Trace id |
| SubmittedById | User to notify (matches ApprovalSubmission.SubmittedById) |

## Error statuses

Recommended:

```text
Approval Error
Approval Submission Failed
Approval Data Error
Approval Routing Error
Approval Status Update Error
```

## Common failure points

- data subflow returns null
- status update fails
- group does not exist
- public group has no active users
- chain name mismatch
- action input invalid
- approval UI subflow missing output variable
- step formula references renamed step
- field missing in target org

## Recovery flow

Create an admin-only Screen Flow:

```text
Select failed approval log
  ↓
Show source record + error
  ↓
Validate prerequisites
  ↓
Terminate stuck interview if needed
  ↓
Reset status
  ↓
Allow resubmission
```
