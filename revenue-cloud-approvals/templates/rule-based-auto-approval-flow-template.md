# Rule-Based Auto-Approval Flow Template

## Flow Name

```text
<auto-approval-flow-api-name>
```

Examples:

```text
<auto-approval-flow-api-name>
<implementation-prefix>_Evaluate_Level 2 Approver_Auto_Approval
<auto-approval-flow-api-name>
```

## Flow Type

Autolaunched Flow.

## Run Context

Invoke from a Background Step in the ApprovalWorkflow.

Recommended:

```text
Run as Automated Process User
```

## Platform Constraints — Background Step Input Limitations

These constraints apply when calling this autolaunched Flow from an orchestration background step:

1. **`varFlowOrchestrationInstanceId` — DO NOT USE as input.**
   `$Flow.OrchestrationInstanceId` exists only in `ApprovalWorkflow` flows, not `AutoLaunchedFlow`.
   Passing it from the orchestration background step causes a type mismatch error at deploy time.
   The Apex wrapper calls `getPreviousRelaRecDetails` without this parameter — the standard action
   resolves the orchestration context automatically from the background step execution environment.

2. **`varStepApiNamesList` (Text Collection) — DO NOT USE as background step input.**
   Collection-typed variables cannot be passed as background step `inputParameters` to an `AutoLaunchedFlow`.
   The deploy error is: `"Enter a valid name for the stepApiNamesList input parameter."`.
   When `stepApiNamesList` is omitted, the standard action returns details for all previous steps.

3. **Only scalar (non-collection) values can be passed** from the background step to the evaluator flow inputs.

## Inputs

| Variable | Type | Required | Notes |
|---|---|---|---|
| `varCurrentRoutingValue` | Number | Depends | Numeric value the approval routes on (e.g. a level or amount) |
| `varCurrentSecondaryValue` | Number | Depends | Optional second numeric value compared the same way |
| `varCurrentSensitiveValue` | Text | Depends | Optional text value whose change forces review |
| `varCurrentMaterialityHash` | Text | Optional | Hash/fingerprint pattern |

**Do NOT add** `varFlowOrchestrationInstanceId` or `varStepApiNamesList` — see Platform Constraints above.

## Apex Output Contract for Custom Logic

If this evaluator is implemented as Apex instead of pure Flow, return a flat output list for direct scalar property binding in the Flow wrapper (recommended Pattern A):

```apex
public static List<Output> evaluate(List<Input> inputs)
```

For collection-style looping outputs or standard wrappers (Pattern B), return a nested collection output list:

```apex
public static List<List<Output>> evaluate(List<Input> inputs)
```

The outer list maps to each request input; the inner list contains the output rows. 

For Pattern A, mapping `canAutoApprove` as a Boolean on the scalar output is the recommended shape. If Pattern B is used with scalar variables, deployment will fail with a field integrity exception (unknown invalid reference).

## Outputs

| Variable | Type | Required | Role |
|---|---|---|---|
| `varCanAutoApprove` | Boolean | Yes | Used by target approval step |
| `varEvaluationReason` | Text | Recommended | Why auto-approval is allowed |
| `varManualReviewReason` | Text | Recommended | Why manual review is required |

## Flow Steps

```text
1. Initialize varCanAutoApprove = false.
2. Call Apex: Get Previous Related Record Details.
3. Decision: Previous data found?
   - No → varCanAutoApprove = false.
   - Yes → continue.
4. Extract previous values.
5. Normalize current and previous values.
6. Compare approval-relevant fields.
7. Decision: Material change?
   - Yes → varCanAutoApprove = false.
   - No → varCanAutoApprove = true.
8. Set evaluation/manual review reason.
9. Return outputs.
```

## Recommended Default

Always initialize:

```text
varCanAutoApprove = false
```

Then set true only after all checks pass.

## Example Comparison Logic (illustrative)

```text
Can auto-approve if:
CurrentRoutingValue <= PreviousRoutingValue
AND CurrentSecondaryValue <= PreviousSecondaryValue + tolerance
AND CurrentMaterialityHash = PreviousMaterialityHash
```

## Example Text-Value Logic (illustrative)

```text
Can auto-approve if:
CurrentSensitiveValue = PreviousSensitiveValue
OR CurrentSensitiveValue is less risky than PreviousSensitiveValue
```

## Approval Workflow Configuration

1. Open the ApprovalWorkflow Flow.
2. In the stage with target approval step, add a Background Step before the approval step.
3. Select the custom autolaunched Flow.
4. Run as Automated Process User.
5. On the target approval step:
   - Start condition: When another step is marked Complete.
   - Step API Name: background step API name.
   - Select Set custom logic for auto-approvals.
   - Auto-Approve Step: `varCanAutoApprove`.
6. Save and activate.
