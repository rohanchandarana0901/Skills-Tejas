# Approvals in Slack Integration

Source: Salesforce Advanced Approvals official documentation. Official considerations: https://help.salesforce.com/s/articleView?id=ind.approvals_slack_considerations.htm&type=5 (verified 2026-06-12)

## Overview

Approvals in Slack enables approvers to approve, reject, and comment on approval requests directly within Slack without navigating to Salesforce. Approval actions taken in Slack are recorded in Salesforce for audit and compliance.

## Official Considerations (documented)

- A **completed work item cannot be reviewed again**, regardless of channel.
- **Group / queue steps:** every active member receives a direct message. If the group or queue has no active members, no Slack notification is sent for that step. Optionally post the step to a **Slack channel** instead (see Channel Strategy). Flow Approval Processes cap group/queue DMs at 100 active members (over the limit → nobody notified); this cap does not apply to unanimous group approval steps in Advanced Approvals.
- **Dynamic Approval Notifications** add an AI-generated summary to direct messages; the summary is not included in channel posts.
- **Delegates do not receive approval notifications in Slack** (email only).
- Submitters receive updates in Slack as work items progress.

## When to Use

Use Approvals in Slack when:
- Approvers need frictionless mobile/async approval workflows
- Approval SLA requires fast turnaround (hours, not days)
- Approvers are distributed across teams/regions and primarily use Slack
- Audit trail completeness is required (actions sync back to Salesforce)
- Approvers are users, or groups/queues (each active member is notified, or the step posts to a channel)

## Architecture Requirements

### Slack Workspace Integration

- Slack workspace must be connected to Salesforce via Slack for Salesforce integration
- Salesforce org must have Advanced Approvals enabled
- Users must have Slack accounts linked to Salesforce

### Approval Workflow Configuration

Slack integration works with:
- ApprovalWorkflow flows (Salesforce Advanced Approvals)
- Any approval step routed to users or groups
- Serial and parallel approval chains
- Dynamic approver routing (user lookups resolve to Slack accounts)

Does NOT work with:
- Classic Approval Process (unsupported)
- Auto-approved steps (no action needed in Slack)
- Steps with no assigned approver

### Slack Channel Strategy

**Default:** Slack integration posts approval notifications to individual approver DMs.

**Channel post (group/queue steps):** in the approval step properties set Approver Type = Group or Queue, select **Send Approval Notification to Slack Channel**, and enter the **Slack Channel ID** (e.g. `C01234ABC`; copy it from the channel's About tab). For a private channel, add the Salesforce app to the channel first. Channel notifications are Advanced Approvals only.

## Implementation Pattern

### Step 1: Verify Slack Integration

```text
Setup → Integrations → Slack for Salesforce
Verify:
  - Workspace connected
  - Slack App installed
  - API permissions include incoming webhooks and messaging
  - Users have linked Slack accounts
```

### Step 2: Enable Approvals in Slack (Org Level)

```text
Setup → Slack (Slack for Salesforce) → connect workspace
Setup → Feature Settings → Approval Settings
  Notify Approvers in Slack ..... Send
  Notify Submitters in Slack .... Send (optional)
Per step (Approver Type = Group/Queue): Send Approval Notification to Slack Channel + Slack Channel ID
```

### Step 3: Configure Approval Workflow for Slack

No special flow configuration required. Slack posts notifications automatically for all approval steps.

Optional: Customize Slack notification message format via:
- Advanced Approvals setup UI → Message templates
- Or via email template customization (see email-templates-advanced-approvals.md)

### Step 4: Test Approver Experience

**Approver in Slack:**
1. Receives notification: "Quote ABC requires your approval"
2. Clicks "View Request" → opens Salesforce approval detail (new tab)
3. Returns to Slack → clicks "Approve" or "Reject"
4. Optional: adds comment in Slack message thread
5. Action recorded in Salesforce immediately

**Submitter in Salesforce:**
1. Sees real-time status change in Approvals app
2. Optional: receives Slack notification of approval completion (if configured)

## Slack Approval Actions

### Available Actions in Slack

| Action | Slack button | Salesforce record | Notes |
|---|---|---|---|
| Approve | "Approve" | Step.Status = 'Approved' | Updates approval work item |
| Reject | "Reject" | Step.Status = 'Rejected' | Triggers rejection logic in flow |
| Comment | Reply in thread | ApprovalWorkItem.Comments field | Visible in Approvals app |
| Delegate | — (not a Slack action) | `ApprovalDelegation` record in Salesforce | Delegation is configured in Salesforce (Approval Settings → Advanced Approval Delegation + delegation records). Delegates get email, not Slack |
| Reassign / Forward | — (not a Slack action) | `reassignApprovalWorkItem` in Salesforce | Approval admin reassigns the work item; see `revenue-cloud-advanced-approvals-invocable-actions` |

### Limitations in Slack

- Cannot edit record data from Slack (view-only)
- Cannot see record changes/field details in Slack (summary view)
- Cannot start new approval request from Slack (submit only from Salesforce)
- Delegates get no Slack notification (email only)
- Group/queue steps with no active members send no Slack notification; Flow Approval Processes cap at 100 active members
- AI summary (Dynamic Approval Notifications) appears in DMs only, not channel posts

## Data Sync & Audit Trail

### Sync Direction

Slack → Salesforce: approval actions taken in Slack are recorded in Salesforce.
Salesforce → Slack: submitters receive updates on their requests in Slack; a work item completed in any channel can't be reviewed again from another.

```text
Slack "Approve" button
  ↓ (immediate)
Salesforce HTTP callout to create work item comment + update status
  ↓ (async)
Flow Orchestration resumes from paused step
  ↓ (dependent on flow logic)
Next approval step or stage completion logic executes
```

### Audit Record

Every Slack action updates:
- ApprovalWorkItem — Status, ReviewedById, ReviewedDate, Comments (there is no separate comment object)
- ApprovalWorkItemHistory (field history)

**Querying Slack-actioned work items in SOQL:**
```apex
SELECT Id, Status, AssignedToId, ReviewedById, ReviewedDate, Comments
FROM ApprovalWorkItem
WHERE Id = :approvalWorkItemId;
```

Query ApprovalWorkItem.Status for the definitive approval decision.

## Common Pitfalls

### Pitfall 1: Approvers Not Linked to Slack

**Symptom:** Approvers don't receive Slack notifications.

**Fix:** Verify in Setup → Users → User Detail → Slack account linked.

### Pitfall 2: Group or Queue Step Sends No Slack Notification

**Symptom:** Group/queue-assigned step, nobody gets a DM.

**Fix:** Confirm the group/queue has at least one active member with a linked Slack account. For Flow Approval Processes, keep membership ≤ 100 active members or use a channel post. Or configure the step to post to a Slack channel (Send Approval Notification to Slack Channel + Slack Channel ID).

### Pitfall 3: Slack Actions Not Syncing Back to Salesforce

**Symptom:** Approver clicks "Approve" in Slack; Salesforce still shows "Pending."

**Check:** 
- Approval step not auto-completed (does flow continue logic?)
- Slack workspace disconnected (verify integration status)
- HTTP callout timeout (check Slack app logs)

**Fix:**
- Review Flow Orchestration instance to see if step completed
- Verify Slack app has current API permissions
- Re-authenticate Slack workspace

## Best Practices

### BP 1: Set Clear SLA in Slack Message

Include approval deadline in Slack notification via email template or custom Flow message action:

```text
Quote ABC requires your approval by 5 PM PT today.
Action: Approve / Reject / View Details
```

### BP 2: Use Shared Channel for Transparency

If approvals are public/transparent (e.g., executive sign-offs), post to shared channel so team can see approval queue and current workload.

**Configure:** on the approval step — Approver Type = Group/Queue, Send Approval Notification to Slack Channel, Slack Channel ID.

### BP 3: Disable Delegation for Sensitive Approvals

Advanced Approval Delegation is org-level (Setup → Feature Settings → Approval Settings → Advanced Approval Delegation); it can't be switched off per step. For compliance-sensitive approvals, either keep delegation off org-wide and use `reassignApprovalWorkItem` / `overrideApprovalWorkItem` by an approval admin, or accept delegation and audit via the Approval Delegation list views (from Me / for Me / All) and the Delegated Approval Work Items list view.

### BP 4: Monitor Slack Approval Latency

Track approval SLA health:
```apex
SELECT COUNT()
FROM ApprovalWorkItem
WHERE Status = 'Assigned'
  AND CreatedDate < :lastNDays(3);
// If high: increase approver capacity or escalate overdue requests
```

### BP 5: Test Slack Disconnection Scenario

If Slack integration fails, Salesforce approval workflows continue independently (Slack is async notification only). Test:

1. Disable Slack for Salesforce
2. Submit approval
3. Verify Salesforce approvals still work
4. Re-enable Slack once issue resolved

---

## Troubleshooting Checklist

- [ ] Slack workspace connected to Salesforce (Setup → Slack for Salesforce)
- [ ] Approvers have linked Slack accounts (User Detail → Slack)
- [ ] Approvals in Slack enabled (Setup → Advanced Approvals)
- [ ] Test approval step routed to individual user (not group)
- [ ] Approver receives Slack notification within 10 seconds
- [ ] Approver clicks "Approve" → status changes in Salesforce within 2 seconds
- [ ] Comment added in Slack appears in ApprovalWorkItem.Comments
- [ ] Audit trail shows Slack user ID in action metadata
- [ ] Check Slack app logs for HTTP errors (Setup → Slack → App Logs)

