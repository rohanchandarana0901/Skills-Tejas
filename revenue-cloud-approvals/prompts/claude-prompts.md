# Claude Prompt Templates

## Design Approval

```text
Use the revenue-cloud-approvals skill.

Before designing, ask:
"Should this approval be record-triggered (auto-fires on record change) or
auto-launched / manually invoked (button, Screen Flow, or explicit submit)?"

Do not proceed with design until the execution model is confirmed.

Design a Salesforce Revenue Cloud Advanced Approval solution for:
<requirement>

Return:
1. assumptions (including confirmed execution model)
2. approval decision framework
3. Flow architecture (entry/trigger design based on execution model)
4. approval rules/chains/steps
5. Smart Approval behavior
6. fault handling
7. testing
8. deployment order
9. troubleshooting notes
```

## Modify Existing Approval

```text
Use the revenue-cloud-approvals skill and convert any provided implementation details into generic approval patterns.

Modify <approval-flow-api-name> to:
<requirement>

Preserve existing formula-based stage completion unless the user asks to change it.
Do not activate draft flows.
Include exact formulas, test cases, and deployment order.
```

## Troubleshoot

```text
Use the revenue-cloud-approvals skill.

Troubleshoot this approval issue:
<issue>

Return layered checks:
1. source fields
2. ApprovalSubmission
3. ApprovalWorkItem
4. FlowInterview
5. debug logs
6. public groups
7. step Smart Approval settings (Use Smart Approval, skip conditions)
8. Flow XML
```

## Smart Approval

```text
Use the revenue-cloud-approvals skill.

Analyze Smart Approval behavior for this resubmission:
<details>

Return:
- whether Smart Approval should apply
- step-level checks
- chain-level checks
- approval history checks
- record modification/materiality checks
- SOQL/debug steps
```

## Rule-Based Auto-Approval Design

```text
Use the revenue-cloud-approvals skill.

Design Rule-Based Auto-Approvals for this approval step:
<STEP NAME>

Business rule:
<WHAT CHANGES SHOULD AUTO-APPROVE VS REQUIRE MANUAL REVIEW>

Return:
1. assumptions
2. target approval step
3. background step design
4. custom autolaunched Flow design
5. Apex action usage
6. Boolean output mapping
7. materiality rules
8. failure behavior
9. test cases
10. deployment steps
```

## Add Rule-Based Auto-Approval to Existing RLM Flow

```text
Use the revenue-cloud-approvals skill and existing <approval-flow-api-name> implementation.

Add Rule-Based Auto-Approval to:
<Level_1_Approver / Level_2_Approver / Approval_Sensitive_Field_Approver / other>

Use a background step before the target approval step.
Use getPreviousRelaRecDetails via Apex wrapper.
Return exact Flow changes, target step configuration, Apex template, and test matrix.
```
