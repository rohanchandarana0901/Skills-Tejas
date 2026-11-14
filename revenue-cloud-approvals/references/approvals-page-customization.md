# Customize Pages for Approvals

> **Examples in this file are illustrative.** Object, field, group and approver names (e.g. Quote, discount, Finance, Manager) are placeholders; substitute the target org's values and mark anything unconfirmed `TODO_VERIFY_IN_ORG`.

Source: Salesforce Advanced Approvals official documentation

## Overview

Advanced Approvals provides customizable Lightning pages where users submit approval requests, review approval status, and manage approval workflows. Customize these pages with Lightning components, custom actions, related lists, and Flow actions to enhance UX and streamline approval processes.

## Pages You Can Customize

### 1. Source Record Page (Quote, Order, etc.)

**Purpose:** Where submitter initiates approval request.

**Default components:**
- Approval summary card (approval chain, current step)
- Submit for Approval button / action
- Related approval records list

**Customizations available:**
- Add custom Lightning component (approval preview, approval matrix)
- Add custom button (e.g., "Withdraw Approval Request")
- Add related lists (approval history, approval work items)
- Add Flow screen (approval recommendation assistant)

### 2. Approval Work Item Detail Page

**Purpose:** Where approver reviews and acts on approval request.

**Default components:**
- Approval decision section (Approve / Reject buttons)
- Approval comments input
- Related source record preview
- Approval chain status

**Customizations available:**
- Add approval-specific fields (approval notes, risk assessment)
- Add related record details (linked customer, related quotes)
- Add approval history timeline
- Add custom decision component (approval score, recommendation)

### 3. Approvals App / Dashboard

**Purpose:** Centralized approvals queue for all approvers.

**Default components:**
- My Pending Approvals list (filtered to current user)
- Approval status dashboard
- Approval SLA indicator

**Customizations available:**
- Add custom reports (approval volume, cycle time)
- Add approval metrics dashboard
- Add quick approval cards (Lightning component)
- Add workflow status gauge

## Implementation Pattern: Submit for Approval Button/Action

### Pattern 1: Standard Submit Action (No Customization)

**Use when:** Default Salesforce submit action meets requirements.

**Default behavior:**
1. User clicks "Submit for Approval"
2. Salesforce submits to approval workflow
3. Approver receives notification
4. Flow Orchestration launches approval steps

**Setup:**
```text
Setup → [Object] Page Layouts or Lightning App Builder

Add standard "Submit for Approval" action:
  - Page Layouts → Record Detail → Buttons → "Submit for Approval"
  - (Or Lightning Record Page → drag "Submit for Approval" action component)

This uses Salesforce's native ApprovalWorkflow submission action.
```

### Pattern 2: Custom Submit Flow / Button

**Use when:** Submission needs validation, preview, or data enrichment before workflow launches.

**Architecture:**
```text
User clicks custom button
  ↓
Custom Flow Screen (approval preview + validation)
  ↓
User confirms submission
  ↓
Flow invokes "Submit for Approval" action
  ↓
Approval workflow launches
  ↓
Approver notified
```

**Implementation:**

Create Screen Flow:
```text
Name: Submit_[ObjectType]_ForApproval_Flow
Trigger: Button click on source object

Inputs:
  - recordId (source record)

Screen 1: Preview Approval Steps
  - Display approval chain (fetch from ApprovalWorkflow flow config)
  - Display estimated approvers (via Flow lookup)
  - Display approval SLA deadline
  - Require user checkbox: "I understand this will lock the record"

Screen 2: Confirmation
  - Display summary
  - Show submit button + cancel button

Action: Invoke Submit for Approval
  - Use Salesforce standard invocable action OR custom Apex action
  - Input: recordId, submission context

Post-Submission Flow:
  - Show success toast
  - Redirect to approval status page
```

### Pattern 3: Approval Preview (Without Submission)

**Use when:** Approver or submitter wants to preview approval chain without starting workflow.

**Reference:** `references/preview-approvals-mechanics.md` (built into Salesforce)

**Setup:**
```text
Advanced Approvals has native "Preview Approvals" action.

On source record page:
  Add button → Invoke "Preview Approval Steps" flow
  
This shows approval simulation without creating work items.
```

## Page Customization: Source Record Page

### Example: Quote Page Customization

**Scenario:** Quote approval page should show:
1. Submit for Approval button (standard)
2. Approval summary card (showing current status, next approver)
3. Approval matrix reference (who approves at what discount level)
4. Related approval history (previous quotes, approval times)
5. Quick links (approval documentation, escalation contact)

**Implementation:**

```text
Setup → Lightning App Builder → [Quote Record Page]

Add components in order:

1. Standard "Submit for Approval" action
   └─ Placed in header

2. Custom Lightning Component: ApprovalSummaryCard
   └─ Displays current approval step, next approver, SLA
   └─ Input: recordId
   └─ Data source: ApprovalWorkItem SOQL query

3. Related List: Approval Work Items
   └─ Shows all approval work items for this quote
   └─ Columns: Step, Approver, Status, Decision Date

4. Custom component: ApprovalMatrixReference
   └─ Shows approval requirements by discount/amount
   └─ Input: quote amount, discount
   └─ Displays rule (e.g., "Discount > 15% requires Finance VP")

5. Related List: Quote Approval History
   └─ Shows past approvals of this quote (resubmissions)
   └─ Columns: Submission Date, Approver, Decision, Approval Time

6. Quick Links Card
   └─ Links to: Approval Guidelines (document), Escalation Contact, FAQ
```

## Page Customization: Approval Work Item Detail Page

### Example: Quote Approval Work Item Page

**Scenario:** Approver reviewing quote approval should see:
1. Quote details (amount, discount, customer)
2. Approval decision section (Approve / Reject / Comments)
3. Related objects (linked customer, sales rep, contract)
4. Approval instructions (approval-type-specific guidance)
5. Escalation option (forward to manager)

**Implementation:**

```text
Setup → Lightning App Builder → [ApprovalWorkItem Record Page]

Add components:

1. Standard Approval Decision Component
   └─ Displays Approve / Reject buttons
   └─ Comment input field
   └─ Automatically submits to approval chain

2. Related Record: Source Quote Details
   └─ Displays Quote Amount, Discount %, Customer, Sales Rep
   └─ Input: WorkItem.ParentObjectId
   └─ Use component: RelatedRecordPreview

3. Custom Component: ApprovalContextPanel
   └─ Displays approval-type-specific info
   └─ Example for Discount Approval:
       - Current discount: 15%
       - Approval authority for your role: up to 20%
       - Approval required because: discount exceeds threshold
       - Similar recent approvals: 3 in last 7 days

4. Related List: Approval Chain Progress
   └─ Shows completed steps, current step, remaining steps
   └─ Columns: Step, Approver, Status, Decision Time

5. Custom Action: Escalate to Manager
   └─ Quick action to forward approval to reporting manager
   └─ Fills in default approver (User.Manager)
   └─ Allows custom message

6. Help Component: Approval Instructions
   └─ Display approval guidelines specific to this workflow
   └─ Fetch from knowledge article or static resource
```

## Related Lists on Approval Pages

### Standard Related Lists

| Related List | Use Case | Default Filter |
|---|---|---|
| Approval Work Items | See all approval requests for a record | Object = Quote |
| Approval Comments | See all approver comments/discussions | ApprovalWorkItemId |
| Approval History | See approval decision timeline | Status = Approved, Rejected |
| Sharing | See who has access to approval request | Shares with approvers |

### Custom Related Lists

Create custom list views filtered by:
- Approval step (show only this step's items)
- Approver (show my pending approvals)
- SLA status (show overdue approvals)
- Approval chain (show same workflow type)

**Example: My Pending Approvals**
```text
SOQL:
  SELECT Id, RelatedRecordId, ApprovalChainName, CreatedDate
  FROM ApprovalWorkItem
  WHERE AssignedToId = :UserId
    AND Status = 'Assigned'
  ORDER BY CreatedDate ASC

Columns: RelatedRecordId (link), ApprovalChainName, CreatedDate, Status
Note: ApprovalWorkItem has no Owner or DueDate field; custom list views
cannot filter by ownership (documented) — use AssignedToId in SOQL/components.
Filter: Current User, Status = Pending
Sorting: Due Date (ascending) — oldest due first
```

## Custom Actions on Approval Pages

### Common Custom Actions

| Action | When to use | Implementation |
|---|---|---|
| Withdraw Approval Request | Submitter cancels pending approval | Flow invokes custom action to set status = Withdrawn |
| Escalate to Manager | Approver delegates to manager | Custom Flow action, updates AssignedTo field |
| Reassign to Peer | Approver assigns to colleague | Custom action with user lookup |
| Request Extension | Approver needs more time | Flow updates DueDate field |
| Flag for Compliance | Approver flags approval for audit | Flow creates compliance record |
| Send Reminder | Escalate pending approval | Flow sends email to approver + manager |

### Example: Withdraw Approval Request Button

**Use when:** Submitter wants to cancel pending approval before completion.

**Setup:**
```text
Source Record Page
  → Custom Action: Withdraw Approval Request
  → Invokes: Withdraw_Approval_Flow

Flow: Withdraw_Approval_Flow
  Inputs:
    - recordId

  Logic:
    Step 1: Query pending ApprovalWorkItem
      SELECT Id FROM ApprovalWorkItem
      WHERE RelatedRecordId = :recordId
        AND Status = 'Assigned'

    Step 2: Recall the submission via standard invocable action
      // Documented constraint: CUD on STANDARD approval-object fields via
      // sObject APIs, Flow Update Records, or triggers FAILS.
      // Use the standard recall/withdraw approval invocable action instead
      // (see revenue-cloud-advanced-approvals-invocable-actions skill).

    Step 3: Notify approvers
      Send email to assigned approvers with withdrawal notice

    Step 4: Update source record
      Set: Quote.Status = 'Draft' (or previous status)

    Step 5: Show confirmation
      Show success toast: "Approval request withdrawn"

Visibility:
  Show only when:
    - Current user = record owner
    - Record has pending approval (use formula condition)
```

## Flow Actions for Approvals

### Standard Advanced Approvals Invocable Actions

| Action | Purpose |
|---|---|
| `recallApprovalSubmission` | Submitter/admin withdraws an in-progress submission |
| `cancelApprovalSubmission` | Admin cancels a submission and its incomplete work items |
| `reassignApprovalWorkItem` | Move a pending work item to a user, group, or queue |
| `reviewApprovalWorkItem` | Reviewer records approve/reject |
| `overrideApprovalWorkItem` | Approval admin decides on the reviewer's behalf |
| `getPreviousRelaRecDetails` | Previous submission's related records (Smart Approval custom logic) |

Exact inputs/outputs: `revenue-cloud-advanced-approvals-invocable-actions`. Preview = Connect REST `POST /services/data/latest/connect/advanced-approvals/approval-submission/preview`. Submission starts from the approval workflow entry point (record action / Request Approvals component).

### Standard record-page components

- **Request Approvals** — lets a submitter choose among up to 10 autolaunched flow approval processes configured for the object.
- **Orchestration Work Guide** — option *Automatically Open Next Work Item* opens the user's next work item from the same running approval process after they complete one (Lightning App Builder and Experience Builder).
- **Approval Agent** (Agentforce) — approvers can act through the agent; actions arrive with `channelType = Agent`.

### Custom Flow Actions for Approvals

**Example: Get Approval Recommendation**
```text
Invocable Action: Get Approval Recommendation
  Input:
    - quoteId (lookup)
    - quoteAmount (number)
    - discountPercent (number)

  Logic:
    - Compare discount against approval matrix
    - Determine if auto-approvable
    - Return: recommendedDecision (Approve/Reject/Manual Review)
    - Return: reason (threshold met, exception, etc.)
    - Return: requiresManualReview (boolean)

  Use in: Background step before approval, or preview flow
```

## Best Practices

### BP 1: Mobile-First Page Design

Approval pages must be mobile-friendly (approvers often act on phones/Slack):

- Stack components vertically (not side-by-side)
- Use large buttons (approval decisions)
- Minimize scrolling (key info above fold)
- Use responsive Lightning components (not fixed widths)

### BP 2: Approval Preview Before Submission

Always let submitter preview approval chain before hitting "Submit":

- Show estimated approvers
- Show SLA deadline
- Show approval criteria
- Allow user to cancel

### BP 3: Clear Approval Status Visibility

Approval status should be visible at top of page:

- Current step
- Next approver (if available)
- Approval SLA deadline
- Time elapsed since submission

### BP 4: Include Approval Instructions

Every approval work item page should have:

- Approval guidelines (what to check, what to approve/reject)
- Related record links (customer, contract, related quotes)
- Escalation contact (if approval needs guidance)
- FAQ section (common approval questions)

### BP 5: Separate Approval Concerns

Don't mix approval UI with record editing:

**Good:**
- Approval page shows decision section + read-only quote details

**Bad:**
- Approval page allows inline editing of quote fields while approval pending

---

## Troubleshooting

### Issue: Submit Button Not Showing

**Cause:** Page customization removed standard action, or user lacks submit permission.

**Fix:**
- Verify page layout includes "Submit for Approval" action
- Check user permissions (Advanced Approvals permission set assigned)
- Verify approval workflow is active (Setup → Advanced Approvals)

### Issue: Related List Showing Wrong Data

**Cause:** Filter condition incorrect, or related object permissions missing.

**Fix:**
- Verify related list SOQL filter
- Check FLS (field-level security) on related object
- Verify object relationship (lookup field).

### Issue: Custom Component Not Rendering

**Cause:** Component input not wired to page data, or Apex class has errors.

**Fix:**
- Verify component input variable = recordId
- Check Apex class has @AuraEnabled methods
- Review browser console for JS errors
- Check component bundle has correct permissions

