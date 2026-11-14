# Generic Approval Design Patterns

## Generic Approval Design Patterns

### Approval Stage Field Design

Use a stage/status field only when it adds reporting, routing, or UI value. Choose the field type deliberately:

| Option | Use when | Tradeoff |
|---|---|---|
| Formula field | Stage is fully derived from approval status, step completion, or business facts | Read-only and avoids manual drift |
| Picklist field | Users or automation must explicitly move between stages | Easier reporting, but requires governance |
| Text field | Integration needs flexible values | Least controlled; avoid where picklist/formula works |

Prefer a **Formula** field for derived approval stage/reporting where users should not manually override the value. Prefer a **Picklist** if stage must be explicitly set by Flow or users.

### Generic Stage Exit Criteria Formula

For each independent approval type, create a completion formula. Example:

```text
Is<ApprovalType>Completed = OR(
  NOT(<approval-type-required-condition>),
  <approval-step-api-name>.Status == 'Completed'
)
```

Then use a stage exit formula like:

```text
OR(
  AND(
    Is<ApprovalTypeA>Completed,
    Is<ApprovalTypeB>Completed,
    Is<ApprovalTypeC>Completed
  ),
  IsRejected
)
```

### Generic Serial Approval Matrix

```text
Level 1 required when <approval-level-field> >= 1
Level 2 required when <approval-level-field> >= 2 and Level 1 approved
Level 3 required when <approval-level-field> >= 3 and Level 2 approved
```

### Generic Parallel Approval Matrix

```text
Commercial approval required when <commercial-condition> is true
Specialist approval required when <specialist-condition> is true
Legal approval required when <legal-condition> is true

Stage exits only when all required parallel approvals complete, or any required step rejects.
```

### Consolidated Role Approval

Use only when Pre-Flight row 12 chose it. One approval step per approver role, started by any of that role's reasons, instead of one step per reason.

```text
Before: RoleStep_ReasonA (entry: reasonA) ; RoleStep_ReasonB (entry: reasonB)   -> same role approves twice
After : RoleStep (entry: reasonA OR reasonB OR reasonC)                          -> role approves once
```

The role can be at any level. Choose the entry shape by whether a lower level comes before it.

**No lower level (first or only level for this role):** custom logic `1 OR 2 OR 3`, where each condition is a reason Boolean. Do not add a prerequisite condition.

```text
entryConditionLogic = 1 OR 2 OR 3
1 = varReasonA EqualTo true
2 = varReasonB EqualTo true
3 = varReasonC EqualTo true
```

**With a lower level before it:** condition 1 is the prerequisite and 2 to 4 are the reasons (direct comparisons only).

```text
entryConditionLogic = 1 AND (2 OR 3 OR 4)
1 = PreviousStep.Outputs.approvalDecision EqualTo "Approve"
2 = varReasonA EqualTo true
3 = varReasonB EqualTo true
4 = varReasonC EqualTo true
```

Variants:
- **Bypass reason:** a reason that skips the lower level uses `(1 AND 2) OR 3`, where 3 is the bypass reason.
- **Any role, any level:** the pattern applies to any approver role, not only a senior one; no seniority is implied. Several reasons for the same role at the same level merge the same way, with or without a lower level before it.

Completion formula includes the single step once (add the step to the rejection formula below too):

```text
IsRoleRequired          = OR(<reasonA formula>, <reasonB formula>, <reasonC formula>)
IsRoleApprovalCompleted = OR(NOT(IsRoleRequired), NOT(ISBLANK(RoleStep.Outputs.approvalDecision)))
```

Rules:
- Do not leave the same role as a second step in another stage; that makes the role approve twice for one record. Put the role in one stage that starts after every level it depends on.
- A merged step has one `ActionInput__ApprovalChainName`. Old per-reason chain names lose their Smart Approval history.
- One email template serves all reasons. To keep reason context, pass a reasons-text value (concatenated reason labels) into the email or submission comments.
- An existing deployed flow is never consolidated unless the user asks; consolidation changes who approves and when.

### Generic Rejection Formula

Include every approval step that can reject the record. Do not leave a parallel chain out of the rejection condition.

```text
OR(
  CONTAINS({!<level-1-step>.Outputs.approvalDecision}, 'Reject'),
  CONTAINS({!<level-2-step>.Outputs.approvalDecision}, 'Reject'),
  CONTAINS({!<specialist-step>.Outputs.approvalDecision}, 'Reject')
)
```

---
