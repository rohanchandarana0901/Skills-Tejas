# Flow Orchestration Fundamentals for Advanced Approvals

> **Examples in this file are illustrative.** Object, field, group and approver names (e.g. Quote, discount, Finance, Manager) are placeholders; substitute the target org's values and mark anything unconfirmed `TODO_VERIFY_IN_ORG`.

Source: Salesforce Advanced Approvals official documentation

## Overview

Advanced Approvals is **powered by Flow Orchestration**, which coordinates complex, multi-team workflows with defined steps, conditional logic, and pauses for user input. The same limitations and best practices that apply to Flow Orchestration also apply to Advanced Approvals.

This document covers Flow Orchestration concepts critical to approval workflow design.

## What Is Flow Orchestration?

Flow Orchestration is a Salesforce Flow process type (`ApprovalWorkflow` in metadata) that:
- Pauses execution for user input (approval decisions, screen interactions)
- Coordinates multi-step processes with conditional logic
- Tracks state across long-running workflows
- Supports serial and parallel execution paths
- Integrates with approvals, screens, and external systems

**Key difference from autolaunched flow:**
- Autolaunched flows execute and complete (no pauses)
- Orchestration flows pause, wait for human input, then resume

## ApprovalWorkflow vs. Autolaunched vs. Record-Triggered

| Characteristic | ApprovalWorkflow | Autolaunched Flow | Record-Triggered Flow |
|---|---|---|---|
| Execution | Pauses for user input | Runs to completion | Triggered on record change |
| Start | Bare start or invoke via action | Explicit invoke | Automatic on record event |
| State tracking | Yes (FlowInterview, orchestration instance) | Limited | No paused state |
| Use case | Approvals, long-running workflows | Utilities, background jobs | Data validation, auto-update |
| Limits | Standard Flow/orchestration governor limits | N/A | Per-trigger limits apply |

## Flow Orchestration Execution Model

### Interview Lifecycle

```text
1. CREATED
   Flow invoked (manually, via button, or API)
   FlowInterview record created
   Initial variables assigned

2. RUNNING
   Flow executes steps in order
   Assignments, decisions, actions fire

3. PAUSED
   Hit a step that requires user input (approval, screen)
   FlowInterview paused = Waiting for user decision
   User can see paused flow in Approvals app

4. WAITING_ON_ASYNC_JOB
   Step invoked async action (Batch Apex, Queueable)
   FlowInterview in waiting state (not user-paused)

5. WAITING_FOR_SCHEDULED_ACTION
   Step scheduled for future (reminder email)
   FlowInterview waiting

6. FINISHED (Success)
   All steps completed, no errors
   Output variables captured

7. FINISHED (Error)
   Step failed, fault handler executed or no fault path
   Flow stopped with error state

8. UNPAUSED
   User made decision (approve/reject)
   FlowInterview resumes from pause point
   Executes remaining steps

9. ABORTED
   User aborted flow (withdrew approval, canceled screen)
   FlowInterview marked aborted
```

## Key Orchestration Concepts

### 1. Steps vs. Actions

**Steps:** Orchestration-specific elements (orchestration step, background step, approval step).

**Actions:** Invocable actions called from within steps (email, update record, Apex action).

```text
Approval Step (orchestration step)
  ├─ Invokes approval action (assigned to user)
  └─ Pauses until user approves/rejects

Background Step (orchestration step)
  ├─ Invokes action (Apex, update, email)
  └─ Continues without pause (async)

Decision (element)
  └─ Evaluates condition, routes to next step
```

### 2. Serial vs. Parallel Execution

**Serial (Sequential):**
```text
Step 1 (Discount Approval)
  ↓ (after approval)
Step 2 (Legal Approval)
  ↓ (after approval)
Step 3 (Finance Approval)
```

All steps execute in order; next step doesn't start until previous completes.

**Parallel (Concurrent):**
```text
Step 1a (Commercial Approval)  ┐
Step 1b (Legal Approval)       ├─ (all run simultaneously)
Step 1c (Finance Approval)     ┘
  ↓ (all must complete)
Step 2 (Final Stage)
```

All steps start together; next stage waits for all parallel steps to finish.

### 3. Pause Points

Orchestration pauses when:

| Pause type | Example | Resume trigger |
|---|---|---|
| Approval | User needs to approve step | Approver clicks Approve/Reject |
| Screen | User must enter data | User clicks Next/Submit on screen |
| Scheduled | Reminder scheduled for future | Time reached, action fires |
| Async job | Batch/Queueable invoked | Job completes |

### 4. Orchestration Instance

An **orchestration instance** is a single execution of an approval workflow.

- Created when flow launched
- Persists across pauses and resumes
- Tracks all step history, decisions, outputs
- Unique ID: `FlowOrchestrationInstanceId` (in flow variables)
- Query: `SELECT Id, Status FROM FlowOrchestrationInstance`

**Uses:**
- Debug approval progress
- Audit approval chain history
- Integrate with external systems

## Key Limitations & Best Practices

### Limitation 1: No Built-In SLA or Auto-Escalation on Pauses

Approval work items wait for approver action — there is no documented auto-abort deadline, and nothing escalates or reassigns automatically while the orchestration is paused.

**Mitigation:**
- Define a business SLA and implement reminder emails (see approval-reminders.md)
- Escalate/reassign long-pending work items via separate automation
- Monitor pending work items (FlowOrchestrationInstance, ApprovalWorkItem.Status)

### Limitation 2: Large Workflow Complexity

Very large orchestrations become hard to maintain and slow to evaluate. No published step-count cap exists for ApprovalWorkflow; standard Flow limits apply.

**Mitigation:**
- Refactor complex workflows into stages and subflows
- Move shared logic to autolaunched subflows
- Condense decision logic

### Limitation 3: No Direct Orchestration Context in Autolaunched Flow

When orchestration calls autolaunched subflow:
- Autolaunched flow cannot access `$Flow.OrchestrationInstanceId`
- Standard actions (getPreviousRelaRecDetails) resolve context automatically
- Must pass data via input variables

**Mitigation (for Rule-Based Auto-Approvals):**
```text
Orchestration Background Step
  └─ Pass scalar values only (no $Flow.OrchestrationInstanceId)
  └─ Calls autolaunched evaluator flow
     └─ Evaluator invokes standard action
        └─ Action resolves orchestration context automatically
```

### Limitation 4: Collection Inputs Not Supported in Background Steps

Background step cannot receive collection inputs from orchestration flow.

**Example of what fails:**
```text
Orchestration:
  varDiscountBreakpoints = ['10', '15', '20']
  Background step input: varDiscountBreakpoints (fails)

Orchestration:
  varHighestDiscount = '20'
  Background step input: varHighestDiscount (works)
```

**Mitigation:**
- Pass scalar values (single values, not lists)
- Move collection logic into autolaunched subflow

### Note: Background Steps Run Synchronously

A background step whose action is synchronous runs synchronously when the approval workflow flow's `apiVersion` matches the org's current API version (see the deployment contract). Keep flows on the current version to avoid queued, asynchronous background steps.

### Limitation 5: No Scheduled Wait (Time-Based Pause)

Orchestration cannot pause for a specific duration (e.g., "wait 5 days").

You **can** schedule a **future action** (send reminder email in 5 days).

You **cannot** schedule a pause and resume.

**Mitigation:**
- Use scheduled action (background step + delay)
- Use reminder flow (autolaunched, scheduled)
- Escalate after SLA time if still pending

### Best Practice 1: Modular Approval Stages

Group approval steps into logical stages:

```text
Stage 1: Data Validation & Enrichment
  ├─ Gather quote details
  ├─ Lookup approval matrix
  └─ Determine approval chain

Stage 2: Approval Chain
  ├─ Discount Approval
  ├─ Legal Approval
  └─ Finance Approval

Stage 3: Post-Approval
  ├─ Update quote status
  └─ Notify stakeholders
```

### Best Practice 2: Fault Handling at Every Step

Every approval step and background step should have fault path:

```text
Background Step (send approval email)
  ├─ Main path (success)
  │   └─ Continue to next step
  └─ Fault path (email failed)
      ├─ Store {!$Flow.FaultMessage} in a text variable
      ├─ Update status = Error
      ├─ Notify admin (email alert, custom notification, or platform event)
      └─ If org has a custom logging object, create a record — ask user which object to use
         (do NOT assume Approval_Action_Log__c exists)
```

### Best Practice 3: Testing Long-Running Workflows

Test orchestration workflows in sandbox with extended timelines:

```text
Test in Developer Sandbox:
  1. Submit approval
  2. Wait for paused state (check FlowInterview status)
  3. Manually approve in Approvals app
  4. Verify flow resumes and completes
  5. Check final status in source record
```

### Best Practice 4: Monitor Orchestration Health

Query orchestration instances regularly:

```apex
SELECT Id, Status, StatusCategory, CreatedDate
FROM FlowOrchestrationInstance
WHERE Status IN ('Paused', 'WaitingOnAsyncJob', 'WaitingForScheduledAction')
  AND CreatedDate < :System.now().addHours(-4)
ORDER BY CreatedDate ASC;
// Returns long-running or stuck approvals
```

## Troubleshooting Orchestration Issues

### Issue: Flow Paused But User Not Assigned

**Symptoms:**
- Approval work item not visible in Approvals app
- FlowInterview status = Paused
- Approver has no action item

**Cause:** Approver routing failed; approver not assigned to step.

**Debug:**
```apex
SELECT Id, AssignedToId, ApprovalChainName, Status
FROM ApprovalWorkItem
WHERE ApprovalSubmission.FlowOrchestrationInstanceId = :instanceId;
// If AssignedToId = null → routing failed
```

**Fix:**
- Verify dynamic approver lookup succeeded
- Check public group membership
- Verify approver user exists and is active

### Issue: Flow Stuck in WaitingOnAsyncJob

**Symptoms:**
- FlowInterview status = WaitingOnAsyncJob > 5 minutes
- Flow appears hung

**Cause:** Batch job or Queueable failed or is taking long time.

**Debug:**
```apex
SELECT Id, Status, ApexJobId
FROM FlowOrchestrationInstance
WHERE Id = :instanceId;

// Query corresponding batch job
SELECT Id, Status
FROM AsyncApexJob
WHERE Id = :apexJobId;
```

**Fix:**
- Check batch logs for errors
- Retry async job
- Implement retry logic in batch class

### Issue: Approval Interview Aborted Unexpectedly

**Symptoms:**
- FlowInterview/orchestration instance status = Aborted or Failed
- No user action triggered abort

**Cause:** Check Setup -> Paused and Failed Interviews and the admin error email. Documented common causes: multiple steps locking the same record simultaneously, or Work Item screen rendering issues (see advanced-approvals-considerations.md, Execution). There is NO documented 24-hour auto-abort for approval work items.

**Fix:**
- Resolve the underlying lock/rendering error and resubmit
- Implement reminder emails and escalation for long-pending items

## Advanced: Orchestration API Integration

### Querying Orchestration Instances

```apex
SELECT Id, DefinitionId, FlowApiName, Status, StatusCategory, 
       CreatedDate, LastModifiedDate
FROM FlowOrchestrationInstance
WHERE FlowApiName = 'Quote_Approval_Orchestration'
  AND Status = 'Paused'
ORDER BY CreatedDate DESC
LIMIT 1000;
```

### Pausing/Aborting Flows via Apex

```apex
// Abort a flow (user cancels approval)
String instanceId = 'orchestrationInstanceId';
Flow.Interview.getOrchestrationStatus(instanceId);
// → Check if instance is still active before aborting

// No direct "abort" API; use approval rejection instead
// Rejection triggers fault handler → custom abort logic
```

### Integrating External Systems

```apex
Background Step
  └─ Invocable Action: Call External API
     ├─ Input: approval data
     ├─ Output: approval decision (JSON)
     └─ Fault: handle API timeout

Next Step
  ├─ Decision: if API returned approval = true
  ├─ Then: invoke auto-approve action
  └─ Else: continue to manual approval
```

---

## Key Takeaways

1. **Advanced Approvals = Flow Orchestration** — all limitations/best practices apply
2. **Pauses are user input** — approval steps, screen flows, scheduled actions
3. **State persists** — orchestration instance tracks history across pauses/resumes
4. **No documented pause deadline** — work items wait for approver action; use reminders/escalation for SLA
5. **Modular design** — break complex workflows into stages and subflows
6. **Fault handling everywhere** — every step needs error handling
7. **Monitor health** — query FlowOrchestrationInstance to find stuck approvals
8. **Test thoroughly** — verify pause/resume behavior in sandbox before production

