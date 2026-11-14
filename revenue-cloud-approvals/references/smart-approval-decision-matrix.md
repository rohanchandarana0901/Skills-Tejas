# Smart Approval Professional Design Guide

## Definition

Smart Approval reduces unnecessary repeated approvals during resubmission by allowing the Advanced Approvals framework to skip eligible approval steps when prior approval history still applies.

Do not describe Smart Approval as a simple bypass. It is conditional and depends on framework configuration, step settings (Use Smart Approval and skip conditions), approver matching, and record/change eligibility.

---

## Two-Layer Enablement

### Step level

The approval step must pass:

```text
ActionInput__CanUseSmartApproval = true
```

### Chain level

The approval chain must have Smart Approval enabled in Advanced Approvals setup.

Both are required.

---

## Decision Matrix

| Question | Why it matters |
|---|---|
| Same source record? | Approval history is record-specific. |
| Same chain? | Smart Approval matches chain context. |
| Same approver or group member? | Approval history must match approver. |
| Previous decision was Approve? | Rejections generally should not auto-approve. |
| Same flow definition version as the original submission? | If the active version changed, Smart Approval is not considered. |
| Chain configuration unchanged? | Changed governance can invalidate prior approval. |
| Approval-relevant fields unchanged? | Material changes should reroute. |
| Step existed previously? | New steps have no approval history. |
| Evaluation flow used as step entry/exit condition? | Entire flow ineligible per Salesforce limitations — move conditions into the workflow directly. |
| Decision node before stage + "When stage starts" step? | Flow ineligible; put the decision criteria directly on the approval step's entry conditions. |
| More than 30 step conditions? | Not supported for Smart Approval evaluation. |
| Apex or Record data type in step condition? | Conditions must use Number or Text data types to be eligible. |
| Previous submission status Rejected or Recalled? | Documented trigger requirement — only resubmissions after Rejected/Recalled status are evaluated. |
| Same active flow definition version as original submission? | Documented — version change between submissions makes the resubmission ineligible. |
| NOT operator in custom entry logic? | Documented — marks the step ineligible; rebuild with positive conditions only. |
| Work item reassigned during the original submission? | Documented — resubmission ineligible; manual review required. |

Documented eligibility rules source: https://help.salesforce.com/s/articleView?id=ind.approvals_smart_approval_limitations.htm&type=5 (verified 2026-06-12)

---

## Recommended Materiality Model

For better governance, track approval-relevant hashes.

Example fields:

```text
Approval_Relevant_Change_Hash__c
Last_Submitted_Discount__c
Last_Submitted_Net_Total__c
Last_Submitted_Approval_Sensitive_Field_Approver__c
Last_Submitted_Terms_Hash__c
Last_Approval_Submitted_At__c
```

Use these fields for guardrails and troubleshooting, not as a substitute for the platform Smart Approval engine.

---

## Examples

### Should usually skip

- description changed
- billing contact changed
- non-approval field changed
- internal notes changed

### Should usually reapprove

- discount increased
- payment terms worsened
- legal term changed
- product exception added
- approver group changed
- approval tier increased

---

## Testing Smart Approval

Test:

1. Submit and approve quote.
2. Resubmit without changing approval-relevant data.
3. Verify whether work item is auto-approved/skipped.
4. Change discount or payment terms.
5. Resubmit.
6. Verify manual approval is required.
7. Query ApprovalSubmission and work items.
