# Email Templates in Advanced Approvals

> **Examples in this file are illustrative.** Object, field, group and approver names (e.g. Quote, discount, Finance, Manager) are placeholders; substitute the target org's values and mark anything unconfirmed `TODO_VERIFY_IN_ORG`.

Source: Salesforce Advanced Approvals official documentation. Official email considerations: https://help.salesforce.com/s/articleView?id=ind.approvals_email_notification_behavior.htm&type=5

## Official Considerations (documented)

- Email notifications require BOTH org settings ON — **Send Approval Work Item Assignment Emails** and **Send Approval Submission Status Email Notifications** (Advanced Approval settings) — AND **Don't send approver notifications** deselected on the approval step.
- Custom templates must be marked **Available for Use**.
- The template's **entity must match the approval workflow's target object**.
- Only **one email template per combination of approval flow + approval step + notification reason**.
- A template associated with an **approval alert content definition record overrides** the custom email specified on the approval step.
- A template not tied to a specific step applies to **all steps that lack a unique template**.
- **Email replies:** the decision keyword (e.g. `Approve`) must be on the FIRST line and the comment on the SECOND line — otherwise the comment is not captured.
- If the org reaches its email limit, approval emails stop until the cool-down period resets or the limit is increased.
- Known bug: emails sent after a reassignment may include the extra word "null" in the body — safe to ignore.

## Overview

Advanced Approvals sends email notifications to approvers and submitters at key approval stages. Custom email templates allow you to:
- Customize message tone and format per approval workflow
- Include dynamic field values from the approval record
- Localize messages for global teams
- Include links to related records and approval details
- Brand emails with company logos/colors

## When to Use Custom Templates

Use custom email templates when:
- Default Salesforce templates don't match your message requirements
- Business wants approval emails to include specific record details (e.g., quote value, discount amount)
- Multi-language support required (same approval chain, different languages)
- Email must include approval-specific instructions for different approver types
- Compliance requires audit trail statements in approval emails

## Email Notification Events in Advanced Approvals

### Events That Trigger Emails

| Event | Default recipient | When it occurs | Customizable |
|---|---|---|---|
| Approval Request Submitted | Approver(s) of first step | Approval step entry condition met | ✅ Yes |
| Approval Request Reassigned | New approver | Approval reassigned (delegate/forward) | ✅ Yes |
| Approval Request Escalated | Manager or escalation path | Approval SLA approaching/exceeded | ✅ Yes |
| Approval Request Approved | Submitter + next step approvers | Step approval granted | ✅ Yes |
| Approval Request Rejected | Submitter + record owner | Step rejected | ✅ Yes |
| Approval Request Completed | Submitter + stakeholders | All approval steps complete | ✅ Yes |
| Approval Reminder | Overdue approvers | Scheduled reminder triggered | ✅ Yes |
| Comments Added | Watchers | Approver adds comment to approval | ✅ Yes |

## Email Template Architecture

### Salesforce Email Template Structure

Email templates in Salesforce use:
- **HTML/plain text format** (choose one or both)
- **Merge fields** to insert dynamic values
- **Related object lookups** to pull data from linked records
- **Conditional logic** (limited in native templates; use Flow for complex cases)

### Merge Fields Available in Approval Templates

**Source record fields:**
```
{!ObjectName.FieldName}  // Quote.Amount, Quote.Status
{!ObjectName.Related__r.FieldName}  // Quote.Account__r.Name
```

**Approval workflow fields** (`ApprovalWorkItem`):
```
{!ApprovalWorkItem.AssignedToId}  // Current approver (user id; resolve name via relationship)
{!ApprovalWorkItem.CreatedDate}  // Work item creation date
{!ApprovalWorkItem.ApprovalChainName}  // Approval chain
{!ApprovalWorkItem.ApprovalConditionName}  // Approval condition/step context
{!ApprovalWorkItem.Status}  // Work item status
{!ApprovalWorkItem.Comments}  // Reviewer comments
```

**Current user/system fields:**
```
{!User.FirstName}  // Approver first name
{!User.Email}  // Approver email
{!Organization.Name}  // Org name
```

**Decision fields** (also on `ApprovalWorkItem`, populated once the approver acts):
```
{!ApprovalWorkItem.ReviewedDate}  // When approved/rejected
{!ApprovalWorkItem.ReviewedById}  // Who acted
{!ApprovalWorkItem.Comments}  // Approver comments
```

There is no `ApprovalAction` object and no due-date field on any approval object —
not on `ApprovalWorkItem`, `ApprovalSubmission` or `ApprovalSubmissionDetail`. A
template that merges a due date has nothing to merge from. Drive deadlines from a
field on the record under approval, or from a scheduled flow that measures age
against `ApprovalWorkItem.CreatedDate`.

There is also no URL field on the work item. Build the link from the record id:
`https://<MY_DOMAIN>/lightning/r/ApprovalWorkItem/{!ApprovalWorkItem.Id}/view`.

## Implementation Pattern

### Step 1: Create Email Template

```text
Setup → Email → Email Templates → New Template

Template Type: Salesforce (for Advanced Approvals)
Subject: [Quote {!Quote.QuoteNumber}] Requires Your Approval - Action needed
HTML Body:
  <html>
    <body>
      <p>Hi {!User.FirstName},</p>
      <p>Quote <strong>{!Quote.QuoteNumber}</strong> from {!Quote.Account__r.Name} requires your approval.</p>
      <table>
        <tr><td>Amount:</td><td>${!Quote.TotalPrice}</td></tr>
        <tr><td>Discount:</td><td>{!Quote.Discount_Percent__c}%</td></tr>
        <tr><td>Submitted by:</td><td>{!Quote.Owner.Name}</td></tr>
        <tr><td>Submitted:</td><td>{!ApprovalWorkItem.CreatedDate}</td></tr>
      </table>
      <p><a href="https://<MY_DOMAIN>/lightning/r/ApprovalWorkItem/{!ApprovalWorkItem.Id}/view">Review and Approve</a></p>
      <p>—<br>Automated from {!Organization.Name}</p>
    </body>
  </html>

Plain Text Body: (optional, for email clients without HTML)
  Quote {!Quote.QuoteNumber} requires your approval. Assigned {!ApprovalWorkItem.CreatedDate}.
  Review: [approval link]
```

### Step 2: Assign Template to Approval Step

```text
Setup → Advanced Approvals → [Approval Workflow] → Step Details

Email Template for step notification:
  Select: "[Quote] Requires Your Approval"
  
Email on approval decision:
  Select: "[Quote] Approval Status Update"

Recipient:
  Approver (automatically resolved from step routing)
  (or specify custom recipient formula)
```

### Step 3: Configure Notification Rules

```text
Setup → Advanced Approvals → [Approval Workflow] → Notification Settings

Send email to:
  ✅ Step approver
  ✅ Record owner
  ✅ Previous approver (for escalation)
  ☐ All approval chain members (optional)
  ☐ Custom recipients (via formula or public group)
```

### Step 4: Test Email Template

```text
Setup → Email → Email Templates → [Template name] → Send Test Email

Select:
  - Test object (Quote, Order, etc.)
  - Email recipient (your email)

Verify:
  - Merge fields populate correctly
  - Formatting renders properly
  - Links point to correct Salesforce pages
```

## Email Template Patterns

### Pattern 1: Standard Approval Request Email

**Use when:** First-time approval submitted, approver assigned.

```html
<h3>Approval Request: {!Quote.QuoteNumber}</h3>

<p>Hi {!User.FirstName},</p>

<p>A new approval request requires your action.</p>

<table border="1">
  <tr>
    <th>Field</th>
    <th>Value</th>
  </tr>
  <tr>
    <td>Quote Number</td>
    <td>{!Quote.QuoteNumber}</td>
  </tr>
  <tr>
    <td>Account</td>
    <td>{!Quote.Account__r.Name}</td>
  </tr>
  <tr>
    <td>Amount</td>
    <td>${!Quote.TotalPrice}</td>
  </tr>
  <tr>
    <td>Discount %</td>
    <td>{!Quote.Discount_Percent__c}</td>
  </tr>
  <tr>
    <td>Approval Step</td>
    <td>{!ApprovalWorkItem.ApprovalConditionName}</td>
  </tr>
  <tr>
    <td>Assigned</td>
    <td>{!ApprovalWorkItem.CreatedDate}</td>
  </tr>
</table>

<p>
  <a href="[approval detail URL]" style="button">Review in Salesforce</a>
</p>

<p>Reply with your approval decision in Slack or click the link above.</p>
```

### Pattern 2: Approval Rejection Notice

**Use when:** Approver rejects the request.

```html
<h3>Approval Rejected: {!Quote.QuoteNumber}</h3>

<p>Hi {!Quote.Owner.FirstName},</p>

<p>Your approval request has been <strong>rejected</strong>.</p>

<table>
  <tr><td>Reason:</td><td>{!ApprovalWorkItem.Comments}</td></tr>
  <tr><td>Rejected by:</td><td>{!User.Name}</td></tr>
  <tr><td>Date:</td><td>{!ApprovalWorkItem.ReviewedDate}</td></tr>
</table>

<p>Please review the feedback and resubmit if needed.</p>

<p><a href="[quote edit URL]">Edit Quote</a></p>
```

### Pattern 3: Escalation Reminder

**Use when:** Approval SLA is approaching or exceeded.

```html
<h3>Approval Reminder: Action Required</h3>

<p>Hi {!User.FirstName},</p>

<p>This approval has been <strong>pending for 24 hours</strong> and requires your attention.</p>

<p><strong>{!Quote.QuoteNumber}</strong> from {!Quote.Account__r.Name}</p>

<p>Please approve or reject this request.</p>

<p><a href="[approval URL]">Take Action Now</a></p>
```

### Pattern 4: Parallel Approval Notification

**Use when:** Multiple approvers in parallel chain; notify when all complete.

```html
<h3>Approval Status Update: {!Quote.QuoteNumber}</h3>

<p>Your request has completed all approvals.</p>

<table>
  <tr><td>Commercial:</td><td>✓ Approved by {!CommercialApprover.Name}</td></tr>
  <tr><td>Legal:</td><td>✓ Approved by {!LegalApprover.Name}</td></tr>
  <tr><td>Finance:</td><td>✓ Approved by {!FinanceApprover.Name}</td></tr>
</table>

<p>Quote status is now: {!Quote.Status}</p>
```

## Advanced: Conditional Email Logic

### Limitation

Native Salesforce email templates have **limited conditional logic**. For complex conditions, use **Flow-generated email** instead.

**Instead of this template:**
```
{!IF(Quote.Discount_Percent__c > 20,
  "High discount; requires CFO approval",
  "Standard approval")}
```

**Use this Flow pattern:**
```text
ApprovalWorkflow Stage Step
  ↓
Evaluate condition in Flow
  ↓
IF discount > 20
  └─ Send email with [High Discount] template
ELSE
  └─ Send email with [Standard] template
```

### Pattern: Flow-Generated Email in Approval Step

Create a `stepBackground` (background step) before approval step to send conditional email:

```text
Background Step
  ↓
Invocable Action: Send Email Action
  ↓
Input: Quote record, Approver user
  ↓
Logic: IF Discount > 20 → include escalation text
  └─ ELSE → standard text
  ↓
Send formatted email
  ↓
Continue to approval step
```

## Email Template Best Practices

### BP 1: Include Call-to-Action

Every approval email must have a direct link to the approval action:

```html
<a href="https://<MY_DOMAIN>/lightning/r/ApprovalWorkItem/{!ApprovalWorkItem.Id}/view">
  Approve or Reject in Salesforce
</a>
```

### BP 2: Show Approval Context

Include 3-5 key fields from the approval record so approver can decide without opening Salesforce:

```
Quote Number, Amount, Discount %, Approval Condition, Date Assigned
```

### BP 3: Localize for Multi-Language Support

Create separate templates per language:
- `[Quote Approval] EN - Requires Your Approval`
- `[Quote Approval] ES - Requiere Su Aprobación`
- `[Quote Approval] FR - Demande Votre Approbation`

Assign based on approver locale (Flow lookup or user language field).

### BP 4: Avoid Hard-Coded Due Dates

Instead of:
```
Please approve by Friday, 5 PM.
```

Use:
```
Please review this work item; it was assigned {!ApprovalWorkItem.CreatedDate}.
```

### BP 5: Include Approver Name (Not Just Role)

Approvers want confirmation that email is addressed to **them**, not a generic title:

```html
<p>Hi {!User.FirstName},</p>  ✅ Personalized
<p>Hi Approval Manager,</p>   ❌ Generic
```

## Troubleshooting

### Issue: Merge Fields Not Populating

**Cause:** Template object doesn't match source record type.

**Fix:** Verify template is created for correct object (Quote, Order, etc.).

### Issue: Emails Sent to Wrong Recipient

**Cause:** Email routing formula incorrect or public group has wrong members.

**Fix:** 
- Check recipient formula in Advanced Approvals setup
- Verify public group membership
- Test with specific user email

### Issue: HTML Formatting Broken in Email Client

**Cause:** Unsupported CSS or HTML in email client.

**Fix:**
- Test in Outlook, Gmail, mobile clients
- Use inline styles instead of `<style>` tags
- Avoid `<div>` layouts; use `<table>` for formatting

### Issue: Too Many Emails Sent (Duplicate Notifications)

**Cause:** Multiple approval steps sending email for same event.

**Fix:**
- Check approval workflow has only one email trigger per step
- Disable org-level email rules that might duplicate
- Verify Flow does not send additional email action

