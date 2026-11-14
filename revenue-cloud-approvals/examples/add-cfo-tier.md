# Example: Add CFO Tier to Discount Approval

## Assumption

Current org uses `<approval-flow-api-name>` and formula-based stage completion.

## Change

Add CFO tier for `<approval-level-field> >= 4`.

## Steps

1. Create Public Group `CFO`.
2. Add `CFO_Approver` step after `Level_3_Approver`.
3. Entry:
   - `ApprovalLevel >= 4`
   - `Level_3_Approver.Outputs.approvalDecision == "Approve"`
4. Chain: `Discount`.
5. Smart Approval: true if governance allows.
6. Update formula:
   ```text
   OR(
     ApprovalLevel == 0,
     AND(ApprovalLevel < 2, Level_1_Approver.Status == 'Completed'),
     AND(ApprovalLevel < 3, Level_2_Approver.Status == 'Completed'),
     AND(ApprovalLevel < 4, Level_3_Approver.Status == 'Completed'),
     AND(ApprovalLevel >= 4, CFO_Approver.Status == 'Completed')
   )
   ```
7. Update `rejectedQuote` with CFO rejection.
8. Test Levels 1,2,3,4 and rejection at each tier.
