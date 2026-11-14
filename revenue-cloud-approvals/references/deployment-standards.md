# Deployment and Activation Standards

## Command notes

- Pass a literal `--target-org <alias>` on every `sf` command. A deploy hook can refuse a command whose target org comes from a shell variable.

## Deployment Order

Use this generic deployment order unless the user provides a target-org sequence:

```text
1. Quote object metadata / custom fields
2. Public Groups / Queues (they must exist before the approval flow deploys; queues use `<queueSobject>`, public groups take only `<name>`)
3. Approval Settings verification (Use Advanced Approvals on) and Use Smart Approval selected on each eligible step (no Smart-Approval-only org toggle; no chain record to create — ActionInput__ApprovalChainName is a free-form string in flow XML)
4. Permission sets / approver access (include field-level security for any new custom field, e.g. an approval-level field)
5. <approval-status-update-flow-api-name>
6. <approval-screen-flow-api-name>
7. <approval-data-subflow-api-name>
8. <approval-flow-api-name>
9. Lightning page / Submit for Approval action
```

## Activation Rules

- All required approval flows must be Active.
- Draft flows must not be activated in production unless explicitly approved.
- `<approval-flow-api-name>` must be activated after its subflows.

## Sandbox Validation

Test:

| Scenario | Expected |
|---|---|
| No approval required scenario | no approval |
| Level 1 | Level 1 Approver only |
| Level 2 | Level 1 Approver then Level 2 Approver |
| Level 3 | Level 1 Approver then Level 2 Approver then Level 3 Approver |
| Approval-sensitive field only | Specialist chain only |
| Discount + Specialist | parallel chain behavior |
| Level 1 Approver rejection | Rejected |
| Specialist rejection | Validate rejection formula includes every rejecting step |
| Resubmission | Smart Approval behavior |
| Missing group member | error/no work item diagnosis |

## Rollback

If deployment fails:

1. Deactivate new orchestration version.
2. Reactivate previous active version.
3. Revert changed formulas.
4. Restore group/chain settings if changed.
5. Clear stuck interviews only after confirming business impact.
