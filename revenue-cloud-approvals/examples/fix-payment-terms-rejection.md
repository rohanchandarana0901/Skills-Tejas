# Example: Fix Missing Rejection Step in Overall Rejection Formula

## Problem

One parallel approval step is missing from the overall rejection formula.

## Impact

A rejected approval step can still route the business record to the Approved path.

## Fix

Update `rejectedQuote`:

```text
OR(
  CONTAINS({!Level_1_Approver.Outputs.approvalDecision}, "Reject"),
  CONTAINS({!Level_2_Approver.Outputs.approvalDecision}, "Reject"),
  CONTAINS({!Level_3_Approver.Outputs.approvalDecision}, "Reject"),
  CONTAINS({!Approval_Sensitive_Field_Approver.Outputs.approvalDecision}, "Reject")
)
```

No stage exit change is required if condition 3 already points to `rejectedQuote`.

## Test

Submit Specialist-only quote with `<approval-sensitive-field> = "<changed-value>"` and reject Approval-Sensitive Field approval. Expected final status: `Rejected`.
