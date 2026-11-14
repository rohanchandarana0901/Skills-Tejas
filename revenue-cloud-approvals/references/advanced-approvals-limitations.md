# Advanced Approvals: Design Constraints & Workaround Patterns

For OFFICIAL documented limitations, system boundaries, and expected behaviors, read `advanced-approvals-considerations.md` FIRST — it mirrors the Salesforce "Advanced Approvals Considerations" hub (ind.approvals_advanced_approvals_considerations.htm) fact-for-fact.

This file covers DESIGN-LEVEL constraints and workaround patterns. These are implementation guidance, not documented platform limits. Do not quote numeric limits from this file as official — Salesforce does not publish numeric limits (step counts, email caps, pause lifetimes) for Advanced Approvals; standard Flow/Apex governor limits and org-wide email limits apply as usual.

## Design Constraints and Workarounds

### Constraint 1: No Time-Based Auto-Approve Pauses

Orchestration cannot pause for a fixed duration then auto-approve ("wait 5 days, then approve").

**Workaround: Scheduled Reminder + Escalation**
```text
Approval Step (waiting on approver)
  ↓
Scheduled reminder flow (see approval-reminders.md)
  ├─ Sends approval reminder email after N days
  └─ Separate escalation automation if still pending
```

### Constraint 2: No Conditional Approval Chain Choice at Submission Time

Submitter cannot pick "chain A or chain B" at submission.

**Workaround: Single Flow, Conditional Steps**
```text
Single approval workflow
  ├─ Stage 1: Evaluate amount
  ├─ Stage 2A: IF amount > $100k → Finance VP (entry condition)
  ├─ Stage 2B: ELSE → Finance Manager (entry condition)
  └─ Stage 3: Post-approval
```
Conditional routing lives inside the orchestration via step entry conditions.
Note (Smart Approval impact): keep conditions ON the approval steps, not in evaluation flows or pre-stage decision nodes — both make the flow ineligible for Smart Approvals (see `advanced-approvals-considerations.md` §9).

### Constraint 3: Record Locked During Approval

By default the submitted record is locked (`shouldLock = true`); approvers cannot edit it — only approve/reject.

**Workarounds:**
- Pre-approval: submitter edits before submitting
- Post-rejection: submitter edits, resubmits
- Approver edits via separate custom flow outside the approval step (then approves)

Related execution behavior: multiple steps locking the same record simultaneously is a documented cause of errored flow state — see `advanced-approvals-considerations.md` §4.

### Constraint 4: No Runtime Reordering of Approval Steps

Step order is fixed at design time.

**Workaround: Parallel Chains + Stage Exit Conditions**
```text
Stage 1:
  ├─ Commercial Approval (parallel)
  └─ Legal Approval (parallel)
Stage exit condition decides which sign-offs are required.
```

### Constraint 5: In-Flight Approvals Keep Old Flow Version

Activating a new flow version does not upgrade paused/running approval instances — they finish on the version they started with.

This also breaks Smart Approval: a resubmission must run the SAME flow definition version as the original submission to be eligible (documented — see `advanced-approvals-considerations.md` §9).

**Workaround:** plan version cutovers; for critical in-flight approvals, recall and resubmit on the new version.

### Constraint 6: Delegation Is Org-Level, Not Per-Step

Advanced Approval Delegation (Setup → Feature Settings → Approval Settings → Advanced Approval Delegation) applies org-wide; it cannot be enabled for some steps and disabled for others. Delegations are `ApprovalDelegation` records (user/group/queue, start/end date, no overlaps, not deletable — shorten `EndDate` to end early).

**Workaround:** if strict per-step control is needed, keep delegation off org-wide and use `reassignApprovalWorkItem` / `overrideApprovalWorkItem` by an approval admin instead. Note: delegates receive email but not Slack notifications (documented — §7).

### Constraint 7: Smart Approval Does Not Prevent Resubmission

Smart Approval auto-completes eligible steps on resubmission; it does not stop unnecessary resubmissions.

**Workaround:** pre-submit validation (flow or validation rule) warning when no material changes exist; or Rule-Based Auto-Approvals for field-level materiality (see `rule-based-auto-approvals.md`).

### Constraint 8: Reminders Don't Auto-Escalate

Reminder flows send emails; they do not reassign or escalate by themselves.

**Workaround: explicit escalation automation**
```text
Hour 0: submitted, approver notified
Hour N: reminder email
Hour 2N: reassign to manager (automation)
Hour 4N: notify director
```

## Troubleshooting Pointers

| Symptom | First check |
|---|---|
| Flow in errored state | Setup → Paused and Failed Interviews; admin error email. Common causes: simultaneous record lock, Work Item screen rendering (§4) |
| "Work item is already completed" | Two group/queue members acted concurrently — first wins, normal behavior (§4) |
| Approver can't see record | OWD Private — temporary-access sharing triggers (`trigger-based-approval-record-sharing.md`); remember ApprovalSubmission records cannot be manually shared (§1) |
| Reviewer sees other steps' work items | Set `ApprovalWorkItem` OWD to Private; extend with criteria-based sharing rules (§1) |
| Trigger/API update on approval object fails | CUD on STANDARD approval fields not allowed via sObject APIs or triggers — use invocable actions; custom fields OK (§3) |
| Sandbox users missing approval features | Run Match Production License in sandbox (§2) |
| Smart Approval never triggers | Check the 7 eligibility rules (§9): previous status Rejected/Recalled, same flow version, no evaluation flows, no pre-stage decision nodes, Number/Text conditions only, no NOT operator, no reassignment in original run |
| Emails missing | Both org-level email settings on + step-level notify not deselected; org email limit cool-down (§6) |
| Group/queue step got no Slack DM | No active members, or Flow Approval Process group > 100 members; or post the step to a Slack channel (§7) |

## Scale & Operations Guidance (non-official, practical)

- Test at realistic volume in sandbox before go-live (bulk submissions, notification delivery).
- Standard Flow interview/governor limits and org daily email limits apply — there are no separate published Advanced Approvals caps.
- Monitor long-pending work items and implement escalation rather than relying on reminders.
- Archive/clean old approval submissions per data-retention policy; index queries by CreatedDate.
- Document the approver runbook: how to act, escalation path, known behaviors (record locked during approval, Slack not real-time, email reply keyword on first line).
