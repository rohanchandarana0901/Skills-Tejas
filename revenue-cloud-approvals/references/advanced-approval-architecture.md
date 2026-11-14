# Enterprise Advanced Approvals Architecture Standards


## Mandatory Trigger-Model Question

Before producing metadata, Apex, or Flow steps, determine how approval is initiated:

> "Should this approval start automatically from a record change, or should it be launched manually/from another process?"

Use the answer only to design the **starter pattern**. The main Revenue Cloud Advanced Approval orchestration should remain an `ApprovalWorkflow` unless the request is only for a helper process.

| Initiation model | Recommended pattern | Notes |
|---|---|---|
| Record-triggered | Record-Triggered Flow starter → submit/launch ApprovalWorkflow | Use after-save, changed-to-meet criteria, and recursion guards. |
| Auto-launched/manual | Button, Screen Flow, Apex, API, or Autolaunched Flow starter → ApprovalWorkflow | Caller controls when approval starts. |
| Auto-approval rule evaluation | Background step → Autolaunched Flow → Invocable Apex | Apex invocable output: `List<Output>` (Pattern A — flat scalar) or `List<List<Output>>` (Pattern B — nested collection) |

---

## Flow Types

### ApprovalWorkflow

Use for the main approval orchestration.

Characteristics:

- Invoked by Advanced Approvals framework.
- Contains `orchestratedStages` and approval/background steps.
- Receives framework inputs such as `recordId`, submitter, comments, and optionally first approver.
- Should not be treated as a normal record-triggered Flow.

### AutoLaunchedFlow

Use for utility logic:

- data retrieval
- status updates
- dynamic approver lookup
- matrix evaluation
- error handling
- notification setup

### Screen Flow

Use for:

- approver UI
- submitter preview
- guided submission
- admin recovery tools

### Record-Triggered Flow

Use only for:

- pre-submission validation
- auto-submit trigger
- status synchronization
- post-approval automation

Do not place approval stages/steps inside record-triggered Flow.

---

## Recommended Modular Architecture

```text
ApprovalWorkflow
├── Stage 1: Data Preparation
│   └── stepBackground → Get Approval Data
├── Decision: Requires Approval?
├── Stage 2: Approval Execution
│   ├── stepBackground → Set Pending
│   ├── stepApproval → Chain A
│   ├── stepApproval → Chain B
│   └── stepApproval → Chain C
├── Decision: Approved or Rejected?
├── Stage 3: Approved Status Update
└── Stage 4: Rejected Status Update
```

---

## Enterprise Completion Formula Pattern

For every approval type:

```text
Is[ApprovalType]Completed =
OR(
  approval_not_required,
  required_approval_step_completed
)
```

Stage exit:

```text
(IsDiscountCompleted AND IsSpecialistCompleted AND IsLegalCompleted) OR IsRejected
```

This keeps the stage exit readable and makes future changes safer.

---

## Stage Design Principles

Use one stage when:

- chains can run in parallel
- chains are part of the same approval round
- exit logic can be expressed as formulas

Use multiple stages when:

- later chain should not even evaluate until earlier chain completes
- different stages have separate lifecycle/status handling
- the business wants distinct approval phases

See `generic-approval-stage-and-exit-patterns.md` (Multi-Stage Sequential Pattern) for the exit formulas and rules. Default to one stage unless the user chooses otherwise.

---

## Record Locking Standard

Default to:

```text
shouldLock = false
canAssigneeEdit = false
```

Use `shouldLock = true` only when edits during approval create business risk.

Use `canAssigneeEdit = true` only when approvers are expected to edit the source record during approval.

---

## Submission UX Standard

For enterprise UX:

```text
Submit Button / Screen Flow
  ↓
Validate record readiness
  ↓
Preview approval chain
  ↓
Show approvers/reasons
  ↓
Submit confirmation
  ↓
Submit approval
```

Preview is preferred for sales-facing processes.
