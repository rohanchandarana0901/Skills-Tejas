# Approval Implementation Templates

## Template: Add Approval Tier

```text
Requirement:
Add [Tier Name] approval when [Approval Level] >= [N].

Implementation:
1. Create Public Group: [Group Name]
2. Add stepApproval: [Step_API_Name]
3. Entry:
   - ApprovalLevel >= [N]
   - [PreviousStep].Outputs.approvalDecision == "Approve"
4. Chain: [Chain Name]
5. Smart Approval: true/false
6. Update completion formula
7. Update rejection formula
8. Test all tiers
```

## Template: Add Independent Chain

```text
Requirement:
Add [Approval Type] approval.

Implementation:
1. Add trigger data to data subflow if needed.
2. Add stepApproval.
3. Create completion formula:
   OR(not_required, step.Status == 'Completed')
4. Add condition to stage exit:
   (existing AND newCondition) OR rejected
5. Add rejection behavior if needed.
6. Test standalone and combined paths.
```

## Template: Dynamic Approver

```text
1. Add data subflow step.
2. Query approver.
3. Output approver Id.
4. Decision: if blank → fallback group/error.
5. Assign step to User using output.
6. Test null and inactive approver.
```

## Template: Approval Error Handler

```text
Inputs:
- SourceRecordId
- FlowName
- StageName
- StepName
- ErrorMessage

Actions:
1. Update status to Approval Error
2. Store ErrorMessage in a text variable
3. Create Approval_Action_Log__c record (if object exists or user agrees to create it)
   // Ask user first: does Approval_Action_Log__c exist in your org?
   // If not, suggest creating it (see observability-debug-framework.md for recommended fields)
4. Notify submitter/admin — email alert, custom notification, or platform event
```
