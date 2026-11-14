# Generic Approval Stage and Exit Criteria Patterns

Use these patterns when converting a customer-specific Advanced Approval implementation into reusable architecture guidance.

> **MANDATORY:** Every `orchestratedStage` containing `stepApproval` steps MUST declare `<exitConditions>`. Omitting them causes Flow Builder to warn "does not have stage exit criteria" and the stage may not advance. See Deployment Contract Rule 8 in SKILL.md.

## Approval Stage Field Design

| Field type | Best use | Notes |
|---|---|---|
| Formula | Approval stage is derived from approval status, required approvals, or completed steps | Preferred when users should not manually edit the stage |
| Picklist | Flow or users explicitly set stage values | Useful for reporting and controlled lifecycle transitions |
| Text | Integration needs flexible values | Avoid unless picklist/formula cannot meet the requirement |

## Formula-Based Completion Pattern

Create one completion formula per approval category.

```text
Is<ApprovalCategory>Completed = OR(
  NOT(<approval-category-required-condition>),
  <approval-step-api-name>.Status == 'Completed'
)
```

## Stage Exit Pattern

```text
OR(
  AND(
    Is<ApprovalCategoryA>Completed,
    Is<ApprovalCategoryB>Completed,
    Is<ApprovalCategoryC>Completed
  ),
  IsRejected
)
```

## Generic Rejection Formula

Include every approval step that can reject the business record.

```text
IsRejected = OR(
  CONTAINS({!<level-1-step>.Outputs.approvalDecision}, 'Reject'),
  CONTAINS({!<level-2-step>.Outputs.approvalDecision}, 'Reject'),
  CONTAINS({!<specialist-step>.Outputs.approvalDecision}, 'Reject')
)
```

## Approval Matrix Example

| Level | Condition | Route to |
|---|---|---|
| Level 1 | `<approval-metric>` > `<threshold-1>` | `<level-1-approver-group>` |
| Level 2 | `<approval-metric>` > `<threshold-2>` and Level 1 approved | `<level-2-approver-group>` |
| Level 3 | `<approval-metric>` > `<threshold-3>` and Level 2 approved | `<level-3-approver-group>` |

## Parallel Approval Example

```text
Commercial approval required when <commercial-condition> is true.
Specialist approval required when <specialist-condition> is true.
Legal approval required when <legal-condition> is true.

Stage exits when all required parallel approval categories complete, or when any required category rejects.
```

## Multi-Stage Sequential Pattern (one stage per level)

Use when the user chose multi-stage (Pre-Flight row 11). Default is a single stage. Each stage is a barrier. If any other approval must run in parallel with the chain with no dependency at all (row 10), use a single stage instead.

```text
Gather data -> Level1 stage -> Level2 stage -> Level3 stage -> [independent-branch stage] -> Decision -> Approved / Rejected outcome stage
```

Per-stage exit formulas (each stage exits as soon as its step is decided, or immediately when the step is not required):

```text
IsLevel1StageComplete = OR(<routingValueSafe> < 1, NOT(ISBLANK(Level1Step.Outputs.approvalDecision)))
IsLevel2StageComplete = OR(NOT(isLevel2Required), NOT(ISBLANK(Level2Step.Outputs.approvalDecision)))
IsLevel3StageComplete = OR(NOT(isLevel3Required), NOT(ISBLANK(Level3Step.Outputs.approvalDecision)))
isLevel2Required      = AND(<routingValueSafe> >= 2, Level1Step.Outputs.approvalDecision = "Approve")
isLevel3Required      = AND(<routingValueSafe> >= 3, Level2Step.Outputs.approvalDecision = "Approve")
```

Rules:
- Step entry conditions stay direct comparisons (routing output, previous step `approvalDecision = "Approve"`); never formulas.
- No Decision element between approval stages; only after the last one.
- After a rejection the later steps never start and their stage formulas evaluate true, so the process falls through to the outcome Decision.
- A stage cannot run alongside the next stage. A stage that exits **withdraws** its still-pending steps (verified), so the stage exit formula must include **every** step in that stage; then the stage is a barrier (verified: the next stage did not start until all steps in the stage were complete, and a rejection in the stage still waited for the other steps).
- Grouped example (user-defined): stage 1 = first level + independent approvals A and B with exit `AND(IsLevel1Done, IsADone, IsBDone)`; stage 2 = next level. Later stages therefore wait for the independent approvals. Fully parallel with no dependency needs the single-stage layout.

## Single Stage vs One Stage Per Level (summary)

| | Single stage | One stage per level |
|---|---|---|
| Independent approvals in parallel with the chain | Yes (same stage, own start conditions) | No (only before or after, as their own stage) |
| Next level starts while an independent approval is pending | Yes (verified) | Not applicable |
| Readability by level | One stage, steps listed together | Clear level-by-level stages |
| Pending steps when a stage exits | Not applicable (one exit, after all required steps) | Withdrawn (verified) |
| Default | Yes | Only if the user chooses it |

