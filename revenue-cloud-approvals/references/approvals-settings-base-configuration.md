# Approvals Settings: Base Configuration

> **Examples in this file are illustrative.** Object, field, group and approver names (e.g. Quote, discount, Finance, Manager) are placeholders; substitute the target org's values and mark anything unconfirmed `TODO_VERIFY_IN_ORG`.

Source: Salesforce Advanced Approvals official documentation

## Overview

Before creating approval workflows, you must complete recommended base configuration in **Approvals Settings**. This document outlines mandatory and optional settings for a production-ready Advanced Approvals implementation.

## Prerequisites

- Advanced Approvals licensed and enabled in org
- System admin or Approvals admin permission
- Users created and assigned appropriate roles/permissions

## Base Configuration Workflow

### Step 1: Access Approvals Settings

```text
Setup → Feature Settings → Approval Settings
```

### Step 2: Configure Required Settings

Navigate to each section below and configure accordingly.

---

## 1. Approval Settings Page (org-level toggles)

### Purpose

The **Approval Settings** page (Setup → Feature Settings → Approval Settings) holds every org-level switch for Flow Approval Processes and Advanced Approvals. These are the actual toggle labels:

| Setting | Recommended | Why |
|---|---|---|
| **Use Flow Approval Processes** | ✅ On | Platform prerequisite for orchestration-based approvals |
| **Use Advanced Approvals** | ✅ On | Enables Advanced Approvals features (chains, Smart Approval, preview, etc.) |
| **Advanced Approval Delegation** | Per policy (default Off) | Lets reviewers delegate to a user, group, or queue for a duration via `ApprovalDelegation` records. Turning it on overrides any delegation set on User records |
| **Send Approval Work Item Assignment Emails to Approvers** | ✅ Send | Emails the assigned user/group/queue (and each delegate) when a work item is created or reassigned |
| **Send Approval Submission Status Email Notifications to Submitters** | ✅ Send | Confirms receipt and final status to submitters |
| **Notify Approvers in Slack** | Per policy | DM approvers when a work item is created or reassigned; requires Slack workspace connected |
| **Notify Submitters in Slack** | Per policy | DM submitters on submission and final status |
| **Send approval work item emails only to queue members** | Per policy (default Off) | Off = queue emails also go to users above the queue in the role hierarchy |

### Configuration Steps

```text
Setup → Feature Settings → Approval Settings
  Use Flow Approval Processes ........................... On
  Use Advanced Approvals ................................ On
  Advanced Approval Delegation .......................... per policy
  Send Approval Work Item Assignment Emails to Approvers  Send
  Send Approval Submission Status Email Notifications ... Send
  Notify Approvers in Slack ............................. per policy (Slack connected first)
  Notify Submitters in Slack ............................ per policy
  Send approval work item emails only to queue members .. per policy
```

Queue views, chain visibility, and assigned-approver display are not org toggles — they come from the standard Approvals list views (Assigned Approval Work Items, Delegated Approval Work Items) and page layouts (see `approvals-page-customization.md`).

---

## 2. Notification Settings

### Purpose

Control who receives approval notification emails and Slack messages.

### Settings (all on the Approval Settings page)

| Setting | Value | Why |
|---|---|---|
| **Send Approval Work Item Assignment Emails to Approvers** | ✅ Send | Approvers (and their delegates) must know an item is pending |
| **Send Approval Submission Status Email Notifications to Submitters** | ✅ Send | Submitter gets receipt + final status |
| **Notify Approvers in Slack** | Optional | Requires Slack for Salesforce; group/queue steps DM each active member or post to a channel configured on the step |
| **Notify Submitters in Slack** | Optional | Submitter progress updates in Slack |
| **Send approval work item emails only to queue members** | Optional | Suppress role-hierarchy fan-out of queue emails |

Per-step Slack channel posting (group/queue steps): in the approval step properties select **Send Approval Notification to Slack Channel** and enter the **Slack Channel ID**.

### Email templates

```text
Email template selection:
  - Assignment notification: [Custom Template] or [Default]
  - Approval decision: [Custom Template] or [Default]
  - Rejection: [Custom Template] or [Default]
  - Reminder: [Custom Template] or [Default] (see approval-reminders.md)

Slack (Approval Settings page):
  ☐ Notify Approvers in Slack
  ☐ Notify Submitters in Slack
  ☐ Per step (group/queue): Send Approval Notification to Slack Channel + Slack Channel ID
```

---

## 3. Smart Approvals

### Purpose

Skip manual review of steps that were already approved when a record is resubmitted. Smart Approvals is configured **per approval step in Flow Builder** — there is no org-level Smart Approval toggle, lookback period, or eligible-field list.

### How it decides

Smart Approvals reuses each step's existing **entry conditions**: if the values that satisfied the step in the previous submission still satisfy it on resubmission, the step is auto-reviewed. Use Rule-Based Auto-Approvals (custom logic + `getPreviousRelaRecDetails`, see `rule-based-auto-approvals.md`) when the decision needs more than the entry conditions.

### Configuration Steps

```text
Setup → Flows → open the approval workflow → select an approval step → Properties
  ☑ Use Smart Approval
  Smart Approval Skip Conditions: e.g. 2, 4
    (comma-separated numbers of start conditions to exclude from evaluation;
     numbering follows the "Requirements to Start Step" list from 1;
     an invalid value or a resource reference = nothing skipped)
Save → activate the flow
```

### Eligibility rules (all must hold)

| Rule | Detail |
|---|---|
| Prior submission status | Previous submission must be **Rejected** or **Recalled** |
| Same flow version | Resubmission must run the same flow definition version as the original; a new active version → not evaluated |
| Condition data types | Entry conditions must use **Number** or **Text** fields |
| No evaluation flows | An evaluation flow as any step's entry/exit condition makes the whole flow ineligible — inline the criteria instead |
| No decision node before a stage | With "When the stage starts, the step starts", a decision node before the stage makes the flow ineligible — move the criteria into the step's entry conditions |
| No NOT operator | Custom entry logic using NOT marks the step ineligible — rebuild with positive conditions |
| No reassignment | A work item reassigned during the original submission makes the resubmission ineligible for that step |

Record-level signals: `ApprovalSubmission.IsEligibleForSmartApproval`, `IsSmartApprovalRun`, `SmartApprvlBasisSubmissionId`; `ApprovalWorkItem.IsEligibleForSmartApproval`, `IsAutoReviewed`, `SmartApprovalBasisWorkItemId`.

---

## 4. Approval Chain & Routing Configuration

### Purpose

Define default approvers and routing rules for approval steps.

Routing is designed in the approval workflow (approver type User / Group / Queue per step, dynamic assignee resolved by a background step); there are no org-level routing settings. Design options:

| Design element | Options | Why |
|---|---|---|
| **Approval matrix** | Custom object or formula field | Dynamic routing based on approval criteria |
| **Default approvers** | Named users or public groups/queues | Fallback when dynamic routing returns null |
| **Escalation contact** | Approval admin (persona with Approval Admin permission) | Can reassign, override, recall, or cancel when routing fails |

### Configuration Steps

**Option A: Custom Approval Matrix Object**

```text
Setup → Objects & Fields → Create Custom Object: Approval_Matrix__c

Fields:
  - Approval_Type__c (Picklist: Discount, Legal, Finance, etc.)
  - Min_Amount__c (Currency)
  - Max_Amount__c (Currency)
  - Approver_Group__c (Lookup to PublicGroup)
  - Region__c (Picklist: US, EU, APAC)
  - Manager_Level__c (Picklist: L1, L2, L3)

Records:
  Discount Approval | Amount >= 10000 | US | Finance VP Group | L3
  Discount Approval | Amount >= 5000  | US | Finance Manager Group | L2
  Discount Approval | Amount >= 1000  | US | Sales Manager Group | L1
  ... (add region/manager variations)
```

**In Flow:**
```text
Background Step: Lookup Approver
  ├─ Query Approval_Matrix__c
  │  WHERE Approval_Type = 'Discount'
  │    AND Amount >= quoteAmount
  │    AND Amount < nextThreshold
  │    AND Region = quoteRegion
  │  ORDER BY Min_Amount DESC (get most specific)
  │
  ├─ Get first matching matrix record
  └─ Extract: Approver_Group__c → use as approval routing

Next Approval Step:
  ├─ Assign to: (lookup result)
  └─ Fallback: [Default Approver Group] if lookup empty
```

**Option B: Formula-Based Routing**

```text
In Approval Step:
  Assign to: (formula field on source object)
  
Quote custom field: Discount_Approver_Group__c (formula)
  CASE(
    IF(Discount_Percent > 20, 'HighDiscount',
      IF(Discount_Percent > 10, 'MediumDiscount', 'LowDiscount')),
    'HighDiscount', 'FinanceVPGroup',
    'MediumDiscount', 'FinanceManagerGroup',
    'LowDiscount', 'SalesManagerGroup',
    'DefaultApproverGroup'
  )
```

---

## 5. Reminders & Escalation (custom)

### Purpose

Advanced Approvals has no built-in SLA timer, reminder schedule, or auto-escalation setting. Reminders and escalations are custom automation on `ApprovalWorkItem` — full pattern and the questions to ask the user in `approval-reminders.md`.

### Design (example — timings, templates, and recipients are user-confirmed, never hardcoded)

```text
Record-Triggered Flow on ApprovalWorkItem (after create), Scheduled Paths:
  Path 1 — N hours after CreatedDate
    Condition: Status = Assigned
    Action: email/Slack reminder to AssignedToId (user, group, or queue)
  Path 2 — M hours after CreatedDate
    Condition: Status = Assigned
    Action: escalation email to approval admin / manager
  Path 3 (optional) — K hours after CreatedDate
    Condition: Status = Assigned
    Action: approval admin reassigns (reassignApprovalWorkItem) or overrides (overrideApprovalWorkItem)

Never auto-approve or auto-reject on timeout.
```

Delegation for planned absences is not a reminder concern — use Advanced Approval Delegation (section 1).

---

## 6. Security & Access Configuration

### Purpose

Give each persona the documented permissions and make sure approvers can reach the source records.

### Personas and permissions (documented)

| Persona | Can | Permissions |
|---|---|---|
| Approval Designer | Design and activate approval workflows | Manage Flow; **Approval Designer**; Read on Approval Submission |
| Approval Submitter | Submit, recall | Run Flows; Read on Approval Submission |
| Approval Reviewer (user, group, or queue) | Receive notifications, review work items | Run Flows; Read on Approval Submission |
| Approval Delegate | Act on work items during an active delegation | Run Flows; Read on Approval Submission |
| Approval Administrator | Org-wide settings; modify, recall, cancel submissions; review or override any work item; sees work item conditions/criteria | Run Flows; **Approval Admin**; Read on Approval Submission |

Package these in permission sets named per your org convention (`TODO_VERIFY_IN_ORG` for existing set names).

### Configuration Steps

```text
Permission sets (one per persona) → assign the permissions above
Advanced Approval Delegation on → reviewers also need access to the Approval Delegation object and the Approvals app (Manage Approval Delegations)

Setup → Sharing Settings (Organization-Wide Defaults)
  ApprovalSubmission: Private (cannot be manually shared; access flows down to its work items)
  ApprovalWorkItem:   Private to keep review steps confidential (reviewers see only items assigned/delegated to them);
                      extend with criteria-based sharing rules on ApprovalWorkItem
  Source object (Quote, Order, ...): approvers need read access —
                      OWD / role hierarchy / sharing rules, or temporary-access triggers (approval-record-access.md,
                      trigger-based-approval-record-sharing.md)

Setup → Process Automation Settings
  ☑ Enable email approval response   (lets approvers/delegates approve or reject by replying to the email;
                                       requires Send Approval Work Item Assignment Emails to Approvers = Send)
```

Field-level security: approvers must be able to read every field referenced by step entry conditions and shown on the work item page.

---

## 7. Approval Workflow Activation

### Purpose

Activate an approval workflow (an `ApprovalWorkflow` flow) in production.

### Mandatory Steps Before Activation

```text
Checklist:
  ☑ Approval workflow designed and tested in sandbox
  ☑ Every approval step has a valid approver (user / group / queue) or a resolved dynamic assignee
  ☑ Email templates created and Available for Use (or defaults accepted)
  ☑ Persona permissions assigned (section 6)
  ☑ Record sharing configured (approvers can access source records)
  ☑ Smart Approval steps flagged (Use Smart Approval) where wanted, and eligibility rules met (section 3)
  ☑ Reminder / escalation automation deployed (section 5), if any
  ☑ Stakeholders notified of go-live
  ☑ Runbook created (approval procedures, escalation contacts)

Activation Steps:
  1. Setup → Flows → open the approval workflow
  2. Activate the flow version
  3. Submit a test record through the approval
  4. Check work item creation, notifications (email / Slack), and the Assigned Approval Work Items list view

Version notes:
  - In-flight submissions keep running on the version they started with.
  - A resubmission is only Smart-Approval-eligible on the same flow version as the original — plan cutovers.
  - Keep the flow apiVersion current so background action steps run synchronously.
```

---

## 8. Observability & Monitoring Setup

### Purpose

Monitor approval health and troubleshoot with the standard objects and views — there is no "monitoring" settings page.

### What to use

| Tool | Purpose |
|---|---|
| **Approval Submission Detail** object | Built-in audit trail — every change on a submission and its work items |
| **Approval Work Item Criteria / Condition** objects | Entry/exit criteria and their evaluated outcomes per step (approval admins) |
| Standard list views | Assigned Approval Work Items, Delegated Approval Work Items (default views can't be edited/deleted; `ApprovalWorkItem` has no Owner-based filtering — filter on `AssignedToId`) |
| Reports / dashboards on `ApprovalSubmission` + `ApprovalWorkItem` | Volume, cycle time (`CreatedDate` → `ReviewedDate`), `Status` mix, per-assignee workload |
| Orchestration run monitoring (Setup → Flow Orchestration runs) | Find paused / stalled runs |
| Custom logging (optional) | Flow fault paths writing to a platform event or custom object — see `fault-handling-standards.md` |

### Configuration Steps

```text
Reports:
  Pending work items:   ApprovalWorkItem WHERE Status = Assigned, grouped by AssignedToId, CreatedDate buckets
  Cycle time:           ApprovalSubmission CreatedDate → LastModifiedDate where Status in (Approved, Rejected)
  Smart Approval usage: ApprovalWorkItem WHERE IsAutoReviewed = true

Scheduled Flow (optional):
  Daily count of Assigned work items older than N hours → notify approval admins

Dashboard: pending by workflow, cycle time, per-assignee workload, rejection reasons (from Comments)
```

---

## Best Practices

### BP 1: Complete Base Configuration Before Activating Workflows

Do not activate approval workflows until all base configuration is complete:
- Approval queue enabled
- Notifications configured
- Smart Approval settings defined
- Routing rules tested
- Security/permissions assigned

### BP 2: Test in Sandbox First

Always test full configuration in sandbox before production:
- Submit test record through approval
- Verify approver receives notification
- Verify approver can access source record
- Verify approval work item appears in queue
- Test escalation/reminder workflows

### BP 3: Document Approval Procedures

Create runbook for approvers:
- How to view pending approvals
- How to submit for approval
- How to handle escalations
- Escalation contact information
- Known limitations (record locked during approval, Slack not real-time, email reply keyword on first line — see advanced-approvals-considerations.md)

### BP 4: Monitor Approval Health Post-Launch

Set up monitoring dashboards:
- Pending approvals by status
- Approval cycle time
- SLA compliance %
- Approver workload
- Rejection reasons

### BP 5: Plan Migration Path for Existing Approvals

If migrating from Classic Approval Process:
- Run parallel approvals for 1-2 weeks (both systems)
- Verify Advanced Approvals handles all use cases
- Archive old Classic workflow
- Communicate cutover to users

---

## Validation Checklist: Production Readiness

Before go-live, verify:

- [ ] Approval queue functional (test viewing pending approvals)
- [ ] Notifications working (test email and Slack)
- [ ] Smart Approval configured (test skip on unchanged fields)
- [ ] Routing dynamic (test approval matrix/formula)
- [ ] SLA tracking (test approval clock, reminders)
- [ ] Security correct (approvers can access records, see fields)
- [ ] Workflows activated in production
- [ ] Monitoring dashboards created
- [ ] Runbook + escalation contacts documented
- [ ] All users trained (how to submit, approve, escalate)

---

## Troubleshooting Common Setup Issues

### Issue: Approvers Don't See Pending Approvals

**Check:**
- [ ] Use Advanced Approvals is on (Approval Settings)
- [ ] Approver has Run Flows + Read on Approval Submission (section 6)
- [ ] Approval work item assigned to approver (check ApprovalWorkItem.AssignedToId)
- [ ] Approver has read access to source record (check OWD / sharing rules)

### Issue: Notification Emails Not Sending

**Check:**
- [ ] Send Approval Work Item Assignment Emails to Approvers = Send (Approval Settings)
- [ ] Step's advanced setting "Don't send approver notifications" is not selected
- [ ] Custom template marked Available for Use and its entity matches the workflow's object
- [ ] Approver email address valid
- [ ] Email-to-Case not blocking (Setup → Email to Salesforce)

### Issue: Smart Approval Not Skipping

**Check:**
- [ ] Use Smart Approval selected on the step
- [ ] Previous submission status was Rejected or Recalled
- [ ] Same flow definition version as the original submission
- [ ] No evaluation flows / NOT logic / decision-node-before-stage / reassignment (section 3 eligibility table)
- [ ] Entry conditions use Number or Text fields

### Issue: Reminder Not Sent

**Check:**
- [ ] Reminder flow is active and its scheduled path offset is from ApprovalWorkItem.CreatedDate
- [ ] Path condition uses Status = Assigned
- [ ] Recipient resolves (AssignedToId may be a user, group, or queue)

