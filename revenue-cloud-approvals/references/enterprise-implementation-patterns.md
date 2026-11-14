# Enterprise Implementation Patterns

> **Examples in this file are illustrative.** Object, field, group and approver names (e.g. Quote, discount, Finance, Manager) are placeholders; substitute the target org's values and mark anything unconfirmed `TODO_VERIFY_IN_ORG`.

## Pattern A — Add Approval Tier to Existing Serial Chain

Use when adding Level 3 Approver, CFO, CSuite, or another tier to an existing discount/commercial chain.

Steps:

1. Create public group or approver source.
2. Add new `stepApproval` after previous tier.
3. Entry condition:
   ```text
   ApprovalLevel >= newThreshold
   AND PreviousStep.Outputs.approvalDecision == "Approve"
   ```
4. Set same approval chain name as existing serial chain.
5. Enable Smart Approval if governance allows.
6. Update completion formula by tightening previous top-tier bound.
7. Update rejection formula to include new step.
8. Test all lower and new tiers.

Do not add many numbered exit conditions. Update the formula.

---

## Pattern B — Add Independent Parallel Approval Chain

Use for Specialist, Legal, Product, Compliance.

Steps:

1. Add approval trigger output to data subflow if required.
2. Add new `stepApproval` in the approval stage.
3. Give it its own chain name.
4. Create formula:
   ```text
   IsLegalApprovalCompleted = OR(not_required, Legal_Approver.Status == 'Completed')
   ```
5. Add formula to stage exit AND group:
   ```text
   (IsDiscount AND IsSpecialist AND IsLegal) OR rejected
   ```
6. Add rejection handling if rejection should reject the record.
7. Test independent, combined, approval, and rejection paths.

---

## Pattern C — Dynamic Approver Lookup

Use when approver depends on record/user/account/product.

Architecture:

```text
stepBackground: Get Dynamic Approver
  ↓
Outputs ApproverUserId
  ↓
Decision: if blank use fallback group
  ↓
stepApproval assigned to User
```

Always provide fallback behavior.

---

## Pattern D — Approval Matrix

Use matrix when routing depends on multiple dimensions.

Suggested object:

```text
Approval_Matrix__c
├── Active__c
├── Approval_Type__c
├── Region__c
├── Country__c
├── Product_Family__c
├── Min_Discount__c
├── Max_Discount__c
├── Min_Amount__c
├── Max_Amount__c
├── Approval_Level__c
├── Approver_User__c
├── Approver_Group__c
└── Priority__c
```

Use a data subflow to query best matching active row.

---

## Pattern E — Approval Preview UX

Recommended for sales users:

```text
Screen Flow Button
  ↓
Validate Quote
  ↓
Preview approvers/chains
  ↓
Show user approval summary
  ↓
Submit confirmation
  ↓
Submit for approval
```

---

## Pattern F — Rejection Handling

Always define:

- which approval steps can reject
- whether any rejection rejects the whole record
- whether each independent chain has separate rejection effect
- status update behavior
- resubmission behavior

Known uploaded baseline gap:

```text
Approval_Sensitive_Field_Approver rejection is not included in rejectedQuote.
```
