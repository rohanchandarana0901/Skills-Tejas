# Generic Stage Exit Criteria Example

Scenario: A business record may require multiple independent approval categories.

## Required Flags

```text
RequiresCommercialApproval = <commercial-condition>
RequiresSpecialistApproval = <specialist-condition>
RequiresLegalApproval = <legal-condition>
```

## Completion Formulas

```text
IsCommercialCompleted = OR(
  NOT(RequiresCommercialApproval),
  <commercial-approval-step>.Status == 'Completed'
)

IsSpecialistCompleted = OR(
  NOT(RequiresSpecialistApproval),
  <specialist-approval-step>.Status == 'Completed'
)

IsLegalCompleted = OR(
  NOT(RequiresLegalApproval),
  <legal-approval-step>.Status == 'Completed'
)
```

## Rejection Formula

```text
IsRejected = OR(
  CONTAINS({!<commercial-approval-step>.Outputs.approvalDecision}, 'Reject'),
  CONTAINS({!<specialist-approval-step>.Outputs.approvalDecision}, 'Reject'),
  CONTAINS({!<legal-approval-step>.Outputs.approvalDecision}, 'Reject')
)
```

## Stage Exit Formula

```text
OR(
  AND(
    IsCommercialCompleted,
    IsSpecialistCompleted,
    IsLegalCompleted
  ),
  IsRejected
)
```
