# Preview Approvals: Mechanics & Best Practices

> **Examples in this file are illustrative.** Object, field, group and approver names (e.g. Quote, discount, Finance, Manager) are placeholders; substitute the target org's values and mark anything unconfirmed `TODO_VERIFY_IN_ORG`.

Source: Salesforce Advanced Approvals official documentation. Official considerations: https://help.salesforce.com/s/articleView?id=ind.approvals_preview_feature_limitations.htm&type=5 (verified 2026-06-12)

## Overview

**Preview Approvals** simulates approval chain execution before submission. Submitter (or approver) reviews estimated approval steps, approvers, and SLA without creating work items or triggering notifications. No record changes occur during preview.

## Official Considerations (documented)

- Preview works **only with the Autolaunched Flow Approval Process (No Trigger)** flow type.
- Steps whose entry conditions depend on runtime/asynchronous evaluations (e.g. subflows in background steps) are **not shown** in preview. Workaround: set **mock output values** for those evaluations in Flow Builder.
- Preview treats every referenced step as a required dependency — it does **not distinguish AND vs OR**. A step configured to start after Step A OR Step B previews as dependent on both.
- Input variables **cannot be passed manually** during preview — configure default values in Flow Builder.
- Dependencies between steps in **different chains** are not shown; steps still appear in sequential order.
- Internal error during preview → verify each stage has a valid exit path and no steps are assigned to approvers of type **Resource**.

Use Preview Approvals to:
- Show submitter who will approve their request
- Estimate approval time
- Validate approval routing logic
- Resolve routing issues before submission
- Educate submitters on approval process

## Preview Approvals Execution

### How Preview Works

```text
User clicks "Preview Approvals" button
  ↓
Flow invokes Preview Approvals action
  Input: source record, submission context
  ↓
Flow evaluates approval chain logic (without committing)
  ├─ Query approval workflow definition
  ├─ Evaluate routing conditions
  ├─ Simulate step entry & exit logic
  └─ Build estimated approver list
  ↓
Returns: simulated approval chain
  ├─ Step names
  ├─ Estimated approvers (by name)
  ├─ Estimated SLA deadline
  └─ Step order (serial/parallel)
  ↓
Display preview to user
  (no work items created, no notifications sent)
```

### What Preview Evaluates

| Element | Evaluated | Example |
|---|---|---|
| **Approval routing formula** | ✅ Yes | "If discount > 20%, route to CFO" |
| **Approver group membership** | ✅ Yes | Public group "Finance_VPs" returns 3 members |
| **Dynamic approver lookup** | ✅ Yes | "Find Sales Manager for this customer" |
| **Conditional steps** | ✅ Yes | "Only if amount > $100k, require Finance VP" |
| **Parallel chains** | ✅ Yes | Shows all parallel approvers simultaneously |
| **Smart Approval eligibility** | ❌ No | Preview shows what *would* be required; Smart Approval applied only at submission |

### What Preview Does NOT Evaluate

| Element | Reason |
|---|---|
| **Smart Approval auto-skip** | Requires comparing to previous submission; not available in preview |
| **External API decisions** | External systems not called in preview |
| **Previous submission history** | History not available; approval is hypothetical |
| **Concurrent submissions** | Only one preview at a time; doesn't account for simultaneous submissions |

---

## Implementation Pattern: Preview Button

### Pattern 1: Standard Preview (No Customization)

**Use when:** Default Salesforce preview action meets requirements.

```text
Setup → [Object] Page Layouts or Lightning App Builder

Add standard "Preview Approvals" action:
  ← Lightning Record Page → drag "Preview Approvals" action component
  
Or:
  ← Page Layouts → Record Detail → Buttons → "Preview Approvals"

This uses Salesforce native Preview Approvals invocable action.
```

**User experience:**
```text
User opens Quote
  ├─ Clicks "Preview Approvals" button
  ├─ Modal opens: "Estimated Approval Chain"
  │  ├─ Step 1: Discount Approval
  │  │  └─ Approver: Finance VP (Jane Smith)
  │  │  └─ SLA: 4 hours
  │  │
  │  ├─ Step 2: Legal Approval (parallel to Step 1)
  │  │  └─ Approver: Legal Counsel (Bob Johnson)
  │  │  └─ SLA: 8 hours
  │  │
  │  └─ Estimated total time: 8 hours (max of parallel)
  │
  ├─ User reviews and confirms
  └─ User either submits or closes preview (no action required)
```

### Pattern 2: Custom Preview Flow (Enhanced)

**Use when:** Default preview doesn't show needed context.

**Scenario:** Quote approval preview should show:
1. Estimated approvers (standard)
2. Discount level & approval authority (custom)
3. Similar recent approvals (for context)
4. Escalation contact (if discount is high)

**Implementation:**

Create Screen Flow: `Quote_Approval_Preview_Enhanced_Flow`

```text
Inputs:
  - quoteId

Screen 1: Approval Chain Summary
  Display:
    - Quote Amount: {!Quote.Amount}
    - Discount %: {!Quote.Discount_Percent__c}
    - Estimated approval steps: (via Preview Approvals action)
    
    Table:
      Step | Approver | Authority Level | SLA
      Commercial | Finance Manager | Up to 15% | 4h
      Legal | Counsel | All terms | 8h
      Finance | VP | All amounts | 2h
    
  Show conditional message:
    IF Discount > 20%: "⚠️ High discount. Requires VP approval."
    IF Amount > $1M: "⚠️ Large deal. Legal review mandatory."

Screen 2: Similar Recent Approvals
  Query:
    SELECT Name, Amount, Discount, ApprovalTime, Decision
    FROM Quote
    WHERE Discount_Percent >= {!Quote.Discount_Percent__c} - 5
      AND CreatedDate >= LAST_N_DAYS:30
      AND Approved = true
    ORDER BY CreatedDate DESC
    LIMIT 3

  Display:
    "Similar quotes approved recently:"
    Quote XYZ | $50K | 22% discount | Approved in 2 hours
    Quote ABC | $75K | 25% discount | Approved in 4 hours

Screen 3: Confirmation
  "Ready to submit?"
  [ Submit for Approval ] [ Cancel ]

Post-Preview Action:
  IF user clicks "Submit for Approval":
    └─ Invoke standard "Submit for Approval" action
  ELSE:
    └─ Close preview, return to quote
```

---

## Preview Approvals vs. Smart Approval

| Aspect | Preview Approvals | Smart Approval |
|---|---|---|
| **Purpose** | Show approvers before submission | Auto-approve if eligible |
| **When it runs** | On demand (button click) | At submission time |
| **Applies to** | Any submission | Only resubmissions |
| **Creates work items** | No | Yes (but auto-completed) |
| **Sends notifications** | No | No (work items auto-approved) |
| **Can be disabled** | Yes (hide button) | Yes (step-level flag) |

**Combined workflow:**
```text
1. User clicks "Preview Approvals"
   → See estimated chain (not affected by Smart Approval)
   
2. User submits quote
   → Smart Approval evaluated
   → If eligible, auto-approves (doesn't show in preview)
   → If not eligible, routes to normal approval chain
```

---

## Preview Routing Scenarios

### Scenario 1: Dynamic Routing

**Setup:**
```text
Quote.Discount_Percent = 18%

Preview evaluates routing logic:
  IF Discount > 20% → Route to CFO
  ELSE IF Discount > 15% → Route to Finance Manager
  ELSE → Route to Sales Manager

Result: Finance Manager
```

**Preview shows:**
```
Estimated Approver: Finance Manager (Sarah Lee)
Step: Discount Approval
SLA: 4 hours
```

### Scenario 2: Multi-Level Hierarchy Routing

**Setup:**
```text
Quote.Amount = $150K
Sales Rep: John Smith
Manager: Alice Chen
Director: Bob Johnson

Preview evaluates hierarchy:
  Level 1 (< $50K): Sales Manager approval
  Level 2 ($50K - $200K): Sales Director approval
  Level 3 (> $200K): VP Sales approval

$150K falls in Level 2 → Route to Sales Director
```

**Preview shows:**
```
Estimated Approver: Alice Chen (Sales Director)
Authority: Up to $200K deals
SLA: 4 hours
Escalation: Bob Johnson (SVP Sales) if overdue
```

### Scenario 3: Parallel Approval Chain

**Setup:**
```text
Quote has:
  - Discount: 22% → requires Finance VP
  - Custom product: yes → requires Product Manager
  - High-value customer: yes → requires Account Executive

All three run in parallel (not serial).
```

**Preview shows:**
```
Step 1 (Parallel):
  ├─ Finance VP: Jane Smith (SLA 4h)
  ├─ Product Manager: Dev Patel (SLA 6h)
  └─ Account Executive: You (SLA 2h)

Estimated completion: 6 hours (longest step)
```

---

## Best Practices for Preview Approvals

### BP 1: Always Offer Preview

Make "Preview Approvals" visible on every record that can be submitted for approval:

```text
Quote Record Page:
  Header: [ Submit for Approval ] [ Preview Approvals ]
```

### BP 2: Preview Before High-Value Submissions

For large/complex deals, preview is critical:

```text
On submit button, check:
  IF Amount > $500K OR Discount > 30%:
    └─ Show warning: "Preview approvals before submitting"
       (don't enforce, but encourage)
```

### BP 3: Show Expected Timeline in Preview

Include SLA information:

```text
"This quote will be reviewed by:"
1. Finance Manager (SLA: 4 hours)
2. Legal Counsel (SLA: 8 hours)

Expected total time: 8 hours (if serial)
                   or 8 hours (if parallel)
```

### BP 4: Include Escalation Contact in Preview

Show who to contact if approval is stuck:

```text
"If approval takes longer than 8 hours:
 Contact: Approval Admin (approval-admin@company.com)
 Escalation: CFO (CFO@company.com)"
```

### BP 5: Explain Routing Logic in Preview

Let submitter understand why certain approvers are needed:

```text
"Discount 22% requires Finance VP approval because:
 Company policy: Discounts > 20% require VP sign-off.
 This protects gross margin."
```

### BP 6: Link from Preview to Approval Guidelines

Include help/documentation link:

```text
[ Preview Approvals ] [ ? Help - Approval Guidelines ]

Help article:
  - What is approval chain?
  - Why is my quote in approval?
  - How long does approval take?
  - What if I disagree with rejection?
```

---

## Troubleshooting Preview Issues

### Issue: Preview Shows Wrong Approver

**Symptoms:**
```
Quote Amount: $500K
Expected approver: VP Sales
Preview shows: Sales Manager
```

**Cause:** Routing formula evaluated incorrectly (likely bad threshold).

**Debug:**
```text
Check routing formula:
  IF Amount > $1M → VP Sales
  ELSE IF Amount > $500K → Director Sales
  ELSE → Manager Sales

$500K matches: Director Sales (not VP)

Fix: Update formula threshold if needed.
```

### Issue: Preview Takes Too Long (> 5 seconds)

**Symptoms:**
```
User clicks Preview Approvals
Modal loads, spinner spins for 10+ seconds
User gives up and submits without preview
```

**Cause:**
- Preview action queries large approval matrix
- Dynamic approver lookup hits many records
- Complex routing formula

**Fix:**
- Add LIMIT to approval matrix query (top 100 records)
- Cache approver lookups (use custom metadata vs. querying objects)
- Simplify routing logic (fewer conditions)

### Issue: Preview Doesn't Match Actual Approval

**Symptoms:**
```
Preview shows: Finance Manager
Submitted approval goes to: CFO
```

**Cause:**
- Approval workflow changed after preview
- Smart Approval kicked in (not shown in preview)
- Routing logic depends on record state (was modified after preview)

**Note:** This is expected behavior if record changed after preview.

**Prevention:**
- Don't modify quote after preview, before submission (keep time short)
- Document that Smart Approval may auto-approve (not shown in preview)
- If record changes, re-preview before submitting

### Issue: Preview Button Not Showing

**Symptoms:**
```
User opens Quote record
No "Preview Approvals" button visible
```

**Cause:**
- Page customization removed button
- User lacks permission to view approvals
- Approval workflow not active

**Fix:**
- Add button to page layout (Setup → Page Layouts → add button)
- Verify Advanced Approvals permission set assigned
- Verify approval workflow is active

---

## Advanced: Custom Preview Flow with Reasoning

**Use case:** Show submitter *why* certain approvers are required (educational).

```text
Custom Flow: Quote_Approval_Preview_With_Reasoning

Screen 1: Estimated Approval Chain
  Display standard preview

Screen 2: Approval Reasoning
  Show decision tree:
    
    "Your quote requires the following approvals:"
    
    ✓ Commercial Review (required for all)
      └─ Assigned to: Finance Manager
      └─ Reason: All quotes require commercial review
    
    ✓ Discount Approval (required, your discount: 22%)
      └─ Assigned to: Finance VP
      └─ Reason: Discounts > 20% require VP approval
         Policy: protect gross margin
    
    ✓ Legal Review (required, custom product selected)
      └─ Assigned to: General Counsel
      └─ Reason: Custom product terms reviewed by Legal
         SLA: 8 hours (legal complexity)
    
    ✗ Region Director Approval (NOT required)
      └─ Reason: Only required for international orders
         (Your order is domestic)

Screen 3: Estimated Timeline
  "This approval chain typically takes:"
    ├─ Best case: 2 hours (all approve on first day)
    ├─ Expected: 6 hours (some back-and-forth)
    └─ Worst case: 24 hours (all escalate once)

Next Steps:
  [ Submit for Approval ] [ Cancel ]
```

---

## Summary

**Preview Approvals** is a critical feature for:
1. **Transparency** — submitters see who approves
2. **Education** — understanding approval requirements
3. **Validation** — catching routing issues before submission
4. **Planning** — estimating approval timeline

Always offer preview alongside standard submit buttons. For large deals, emphasize preview to improve submitter experience and reduce rework/rejections.

