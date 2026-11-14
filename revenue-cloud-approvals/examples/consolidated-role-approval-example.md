# Consolidated Role Approval Example

Illustrative only. Object, field, variable, queue, and step names are placeholders. Adapt to the user's object and requirement.

> Two shapes exist. This main scenario has a prior-level role before the merged role. If the merged role is the first or only level, skip to **Variant: same level, no prior-level role** at the bottom: no prerequisite condition is added.

## Scenario

A role (`<role>`, any role at any level) must approve a record for any of three reasons: reason A, reason B, or reason C. A prior-level role (`<prior-role>`) approves first when reason A or reason B applies. Reason C goes straight to the role. The user wants the role to approve once, not once per reason (Pre-Flight row 12).

## Anti-pattern: one step per reason for the same role, or the same role in two stages

```text
Stage 1 Approvals:  PriorStep -> RoleStep_A        (reason A)
Stage 2 Terms:      PriorStep_2 -> RoleStep_B      (reasons B, C)
```

The same role's queue gets two work items for one record. Smart Approval is often enabled on one stage only, which makes repeat approvals worse.

## Pattern: one step per role

Gather stage computes one Boolean per reason and passes them to flow variables:

| Variable | Meaning |
|---|---|
| `varReasonA` | reason A applies |
| `varReasonB` | reason B applies |
| `varReasonC` | reason C applies |

Steps in one approvals stage:

```text
PriorStep   entry: varReasonA = true OR varReasonB = true          (custom logic: 1 OR 2)
RoleStep  entry: (PriorStep approved AND (varReasonA OR varReasonB)) OR varReasonC
                   (custom logic: (1 AND (2 OR 3)) OR 4)
```

RoleStep entry conditions, XML shape (direct comparisons only, no formula references):

```xml
<entryConditionLogic>(1 AND (2 OR 3)) OR 4</entryConditionLogic>
<entryConditions>
    <conditionType>EntryCondition</conditionType>
    <leftValueReference>PriorStep.Outputs.approvalDecision</leftValueReference>
    <operator>EqualTo</operator>
    <rightValue><stringValue>Approve</stringValue></rightValue>
</entryConditions>
<entryConditions>
    <conditionType>EntryCondition</conditionType>
    <leftValueReference>varReasonA</leftValueReference>
    <operator>EqualTo</operator>
    <rightValue><booleanValue>true</booleanValue></rightValue>
</entryConditions>
<entryConditions>
    <conditionType>EntryCondition</conditionType>
    <leftValueReference>varReasonB</leftValueReference>
    <operator>EqualTo</operator>
    <rightValue><booleanValue>true</booleanValue></rightValue>
</entryConditions>
<entryConditions>
    <conditionType>EntryCondition</conditionType>
    <leftValueReference>varReasonC</leftValueReference>
    <operator>EqualTo</operator>
    <rightValue><booleanValue>true</booleanValue></rightValue>
</entryConditions>
```

Stage exit formulas (formulas are used here only, never in entry conditions):

```text
IsPriorRequired  = OR(varReasonA, varReasonB)
IsRoleRequired = OR(AND(IsPriorRequired, PriorStep.Outputs.approvalDecision = "Approve"), varReasonC)

IsApprovalsStageComplete = AND(
  OR(NOT(IsPriorRequired),  NOT(ISBLANK(PriorStep.Outputs.approvalDecision))),
  OR(NOT(IsRoleRequired), NOT(ISBLANK(RoleStep.Outputs.approvalDecision)))
)

IsAnyRejected = OR(
  CONTAINS({!PriorStep.Outputs.approvalDecision},  "Reject"),
  CONTAINS({!RoleStep.Outputs.approvalDecision}, "Reject")
)
```

Rejection by the prior-level role makes `IsRoleRequired` false for reason A or B, so the stage exits and the process falls through to the rejected outcome. Reason C still reaches the role in parallel.

## Observed in a real org (not a rule)

A live flow of this shape used entry conditions that referenced Boolean formulas directly, and an exit formula based on `Step.Status = 'Completed'` instead of a non-blank `approvalDecision`. Both appear to work, but this skill keeps direct variable comparisons in `<entryConditions>` and the `approvalDecision` form for exit. Mark any use of the observed forms `TODO_VERIFY_IN_ORG` and test before relying on them.

## Test matrix

| Case | Expected |
|---|---|
| Only reason A | Prior, then Role once |
| Only reason C | Role only, no Prior |
| Reasons A and C | Prior runs; Role runs once after Prior approves, not twice |
| Prior rejects with A | Role does not start for A; record rejected |
| Resubmit after changing only reason B | Per the Pre-Flight row 5 choice: Smart Approval with skip conditions, custom auto-approve, or full re-approval |
| No reasons | No approval required path (Required Process Skeleton, part 4) |

## Variant: same level, no prior-level role

Consolidation does not need a prior-level role. If one role (`<role>`) is the only approver, or sits at the same level for several reasons, merge it the same way: one step, entry `1 OR 2 OR 3` over the reason Booleans, no prerequisite condition.

```text
Before: RoleStep_A (entry: varReasonA) ; RoleStep_B (entry: varReasonB)   -> same role, same level, two tasks
After : RoleStep   (entry: varReasonA OR varReasonB)                      -> one task
```

Exit formula: `OR(NOT(IsRoleRequired), NOT(ISBLANK(RoleStep.Outputs.approvalDecision)))`, with `IsRoleRequired = OR(varReasonA, varReasonB)`. Include `RoleStep` in the rejection formula.
