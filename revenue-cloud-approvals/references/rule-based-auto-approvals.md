# Rule-Based Auto-Approvals

> **Examples in this file are illustrative.** Object, field, group and approver names (e.g. Quote, discount, Finance, Manager) are placeholders; substitute the target org's values and mark anything unconfirmed `TODO_VERIFY_IN_ORG`.

Source: https://help.salesforce.com/s/articleView?id=ind.approvals_define_custom_logic_auto_approvals.htm&type=5 (verified 2026-06-12)

## Purpose

Rule-Based Auto-Approvals allow an approval workflow to skip manual review during resubmission based on custom rules. The pattern compares the current submission’s record details against the previously submitted record and auto-approves only when the changes are not significant.

Use this pattern when Smart Approval alone is not granular enough and the business needs custom field-level comparison logic.

## Salesforce Standard Pattern

Salesforce’s recommended pattern is:

```text
Approval Workflow Stage
  ↓
Background Step before target approval step
  ↓
Custom Autolaunched Flow
  ↓
Apex Action: retrieve previous submitted record details
  ↓
Custom evaluation logic returns Boolean
  ↓
Target Approval Step
  ↓
Set custom logic for auto-approvals
  ↓
Auto-Approve Step = Boolean output
```

## Required Platform Conditions

Available in Lightning Experience for Enterprise, Unlimited, and Developer Editions where Advanced Approvals is enabled.

Required permissions to configure approval step properties:

```text
Approval Designer
OR
Manage Flow
```

Before implementation, ensure:

- Advanced Approvals is enabled.
- Approval workflow exists.
- Workflow has at least one stage.
- Workflow has at least one target approval step.
- A background step can be added before the target approval step.
- Custom autolaunched Flow can invoke Apex.
- Target approval step supports custom logic for auto-approvals.

## When to Use

Use Rule-Based Auto-Approvals when:

- resubmissions are common
- only significant field changes should require manual approval
- specific fields must be compared across submissions
- Smart Approval history matching is not sufficient
- approval policy depends on field-level materiality
- different approval steps have different auto-approval rules

Examples:

| Scenario | Auto-approve? |
|---|---|
| Description changed only | Usually yes |
| Billing contact changed only | Usually yes |
| Discount unchanged or decreased within approved range | Usually yes, if policy allows |
| Discount increased | Usually no |
| Approval-sensitive field worsened | Usually no |
| Legal clause changed | Usually no |
| Product exception added | Usually no |

## When Not to Use

Do not use Rule-Based Auto-Approvals when:

- all resubmissions must be manually reviewed
- legal/compliance review must always occur
- the step lacks reliable previous-submission data
- comparison logic cannot be clearly explained/tested
- the approval step should always run for audit reasons
- the business cannot define materiality rules

## Design Decision Matrix

| Decision | Recommendation |
|---|---|
| Compare header fields only | Use custom autolaunched Flow variables and Apex previous detail retrieval. |
| Compare related line records | Retrieve previous related record details for the relevant approval step API names. |
| Compare many fields | Compute a stable hash/fingerprint. |
| Compare monetary values | Apply tolerance rules, currency handling, and rounding. |
| Compare picklist/text values | Normalize case/spacing if business allows. |
| Compare line collections | Match by stable key, not list order. |
| No previous submission exists | Return false unless business explicitly allows auto-approval. |
| Previous data retrieval fails | Return false and route to manual approval. |

## Architecture

### Pattern A — Per-step evaluator (one background step per approval step, same stage)

```text
Stage_Approvals
  ↓
Background Step: Evaluate_Level_1_Approver_Auto_Approval
  ↓ (background step precedes target approval step in same stage)
Approval Step: Level_1_Approver
  ↓ "Set custom logic for auto-approvals" → varCanAutoApprove from evaluator flow
  ↓
Background Step: Evaluate_Level_2_Approver_Auto_Approval
  ↓
Approval Step: Level_2_Approver
```

Requires "Start When / When another step is marked Complete" dependency configured in Flow Builder UI on the target approval step (background step API name).

### Pattern B — Single evaluator in Stage_Prep (all approval steps in later stage)

```text
Stage_Prep
  ↓
Background Step: Data_Prep (retrieves current record data)
  ↓
Background Step: Auto_Eval (evaluator flow → Apex → canAutoApprove)

Stage_Approvals
  ↓
Approval Step: Manager_Approval
  "Set custom logic for auto-approvals" → Auto_Eval.Outputs.varCanAutoApprove
  ↓
Approval Step: Director_Approval
  "Set custom logic for auto-approvals" → Auto_Eval.Outputs.varCanAutoApprove
  ↓
Approval Step: VP_Approval
  "Set custom logic for auto-approvals" → Auto_Eval.Outputs.varCanAutoApprove
```

Stage ordering guarantees Stage_Prep completes before Stage_Approvals starts. "Start When" dependency NOT needed on approval steps — no same-stage background step to reference. A single `varCanAutoApprove` Boolean is shared by all approval steps.

> **Valid only when identical logic applies to all steps.** For step-specific decisions (e.g. Manager=Approved but VP=Rejected on prior submission), use Pattern A or `per-step-custom-auto-approve.md` instead — a shared boolean cannot distinguish per-step prior outcomes.

Use Pattern B when:
- Same auto-approve decision applies to all approval steps (e.g. discount level comparison)
- Evaluator only needs to run once regardless of number of approval tiers
- Cleaner orchestration structure is preferred

Use Pattern A when:
- Different auto-approve logic applies per step (step-specific field comparison)
- Different data must be retrieved for each approval step

### Shared subflow architecture (both patterns)

```text
Autolaunched Flow: <auto-approval-flow-api-name>
  ↑
Apex action: ApprovalPreviousRelatedRecordDetails.getPreviousRelaRecDetails
  ↑
Standard action: getPreviousRelaRecDetails
```

## Background Step Configuration

Create a background step immediately before the target approval step.

Recommended naming:

```text
Evaluate_[ApprovalStep]_Auto_Approval
```

Example:

```text
Evaluate_Level 1 Approver_Auto_Approval
Evaluate_Level 2 Approver_Auto_Approval
Evaluate_Approval_Sensitive_Field_Approver_Auto_Approval
```

Configuration:

| Property | Recommended value |
|---|---|
| Step Type | Background Step |
| Action | Custom autolaunched Flow |
| Run As | Automated Process User |
| Condition | Same business scope as target step, or broader |
| Position | Before target approval step |
| Output | Boolean variable used by target step |

## Target Approval Step Configuration

On the target approval step in Flow Builder UI:

**When evaluator background step is in the SAME stage as the approval step (Pattern A):**

1. Select:
   ```text
   When another step is marked Complete, the step starts as the condition
   ```
2. For Step API Name, enter the background step API name.
3. Select:
   ```text
   Set custom logic for auto-approvals
   ```
4. For Auto-Approve Step, select the Boolean output from the evaluator flow.

**When evaluator background step is in an EARLIER stage (Pattern B — Stage_Prep):**

1. Skip "Start When" — stage ordering already guarantees the evaluator has completed.
2. Select:
   ```text
   Set custom logic for auto-approvals
   ```
3. For Auto-Approve Step, select the Boolean output from the Stage_Prep background step (e.g. `Auto_Eval` → Outputs → `varCanAutoApprove`).

In both cases, "Set custom logic for auto-approvals" cannot be configured via Flow XML — it must be set in the Flow Builder UI after deployment.

## Apex Invocable Output Contract

There are two valid output signatures depending on how the Flow evaluates and maps the custom auto-approval decisions:

### Pattern A — Flat/Scalar Output (Recommended for Autolaunched Evaluator Flow Wrapper)
Use this signature when the Apex action is called inside an Autolaunched Flow (the evaluator background subflow) and you want to bind its output fields directly as scalar variables (e.g. `{!Evaluate_Levels.canAutoApprove}`) using `storeOutputAutomatically=true`.

```apex
@InvocableMethod(label='Evaluate Auto-Approval Custom Logic')
public static List<Output> evaluate(List<Input> inputs) {
    List<Output> responses = new List<Output>();
    for (Input request : inputs) {
        Output result = new Output();
        result.canAutoApprove = false; // Safe default
        // custom comparison logic here...
        responses.add(result);
    }
    return responses;
}
```

> [!WARNING]
> If you return `List<List<Output>>` (nested) and attempt to map its properties directly as scalar elements in the Flow (e.g. `{!Evaluate_Levels.canAutoApprove}`), the Metadata API/Flow deployment will fail with a **field integrity exception (unknown invalid reference)**. Returning a nested collection makes the Flow engine treat the action output as a collection, not a scalar.

### Pattern B — Nested Collection Output (Required for direct collection handling or standard wrappers)
Use this signature only when the Flow loops over multiple returned rows (e.g., retrieving previous list records). This is the pattern used by the standard `getPreviousRelaRecDetails` wrapper.

```apex
@InvocableMethod(label='Get Details Wrapper')
public static List<List<SObject>> getDetails(List<FlowInputs> inputs)
```

---

## Generic Step-Specific Auto-Approval Pattern
To keep the evaluator completely generic and reusable across different objects and processes, do **not** hardcode step labels or role names (e.g., Manager, Director, VP) as separate output variables. Instead, pass the target step label as an input parameter and return a single `canAutoApprove` flag.

### Generic Apex Implementation:
```apex
public class Input {
    @InvocableVariable(label='Record ID' required=true)
    public Id recordId;

    @InvocableVariable(label='Current Approval Level' required=true)
    public Decimal currentApprovalLevel;

    @InvocableVariable(label='Previous Approval Level' required=true)
    public Decimal previousApprovalLevel;

    @InvocableVariable(label='Target Step Label' required=true)
    public String targetStepLabel;
}

public class Output {
    @InvocableVariable(label='Can Auto Approve')
    public Boolean canAutoApprove = false;
}
```

In the evaluation loop, dynamically match the step label:
```apex
// Query completed work items for this record
List<ApprovalWorkItem> workItems = [
    SELECT Status, FlowOrchestrationWorkItem.Label 
    FROM ApprovalWorkItem 
    WHERE RelatedRecordId = :request.recordId AND Status IN ('Approved', 'Rejected')
    ORDER BY CreatedDate DESC
];

Map<String, String> latestStatusByStep = new Map<String, String>();
for (ApprovalWorkItem wi : workItems) {
    if (wi.FlowOrchestrationWorkItem != null && !String.isBlank(wi.FlowOrchestrationWorkItem.Label)) {
        String label = wi.FlowOrchestrationWorkItem.Label;
        if (!latestStatusByStep.containsKey(label)) {
            latestStatusByStep.put(label, wi.Status);
        }
    }
}

// Check status of the specific target step being evaluated
result.canAutoApprove = (latestStatusByStep.get(request.targetStepLabel) == 'Approved');
```

## Boolean Output Standard

Use explicit Boolean output names (no spaces — Flow variable API names must be alphanumeric/underscore):

```text
varCanAutoApproveLevel1Approver
varCanAutoApproveLevel2Approver
varCanAutoApproveSpecialist
varCanAutoApproveLegal
```

Do not use ambiguous names like:

```text
result
flag
isValid
```

## Evaluation Logic Standard

The evaluation should return:

```text
true  = safe to auto-approve target step
false = manual review required
```

Default to `false` when uncertain.

## Recommended Evaluation Rules

### Discount Approval

Auto-approve only if:

- discount did not increase
- approval level did not increase
- net total did not materially increase
- product mix did not materially change
- approval-relevant line items did not change

Manual review required if:

- discount increased
- approval level increased
- new restricted product added
- quote total increased beyond tolerance
- previous approval data cannot be retrieved

### Specialist / Approval-Sensitive Field Approval

Auto-approve only if:

- payment terms unchanged or improved
- billing frequency unchanged
- billing profile unchanged
- payment method risk unchanged

Manual review required if:

- payment terms worsened
- payment term changed from <baseline-value> to <changed-value>
- billing policy changed
- credit-risk field changed

### Legal Approval

Auto-approve only if:

- legal terms hash unchanged
- no new non-standard clauses
- no redline/legal exception changed

Manual review required if:

- indemnity/liability/termination terms changed
- non-standard clause added
- contract template changed

## Current vs Previous Data Comparison Pattern

Recommended comparison flow:

```text
Current submission data
  ↓
Previous related record details
  ↓
Normalize values
  ↓
Compare approval-relevant fields
  ↓
Apply materiality/tolerance rules
  ↓
Return Boolean
```

## Field Materiality Matrix

Maintain a matrix for each approval step:

| Field | Auto-approve if changed? | Rule |
|---|---|---|
| Description | Yes | Non-material |
| Discount | No if increased | Manual if current > previous |
| Approval Level | No if increased | Manual if current > previous |
| Approval-Sensitive Field | No if worsened | Manual if risk increases |
| Net Total | Maybe | Use tolerance threshold |
| Product Family | No for restricted products | Manual if new restricted family |
| Legal Terms Hash | No | Manual if changed |

## Platform Constraints — Background Step to AutoLaunchedFlow

These constraints are confirmed from production deployment experience and apply to any evaluator flow called as a background step in an ApprovalWorkflow:

### Constraint 1 — flowOrchestrationInstanceId

`$Flow.OrchestrationInstanceId` is only available in `ApprovalWorkflow` flows, not in `AutoLaunchedFlow`.

**Do NOT** add a `flowOrchestrationInstanceId` input variable to the evaluator flow and attempt to pass `$Flow.OrchestrationInstanceId` from the orchestration background step. This causes a type mismatch error at deployment:

```text
field integrity exception: The type for the input parameter "flowOrchestrationInstanceId"
doesn't match the type for the assigned value.
```

**Correct approach**: Call `Invocable.Action.createStandardAction('getPreviousRelaRecDetails')` without setting `flowOrchestrationInstanceId`. The standard action automatically inherits the orchestration instance context from the background step execution environment.

### Constraint 2 — stepApiNamesList (collection inputs)

Collection-typed flow variables (e.g. `Text Collection`) cannot be passed from an orchestration background step to an `AutoLaunchedFlow` input parameter. Attempting this causes a deployment error:

```text
field integrity exception: Enter a valid name for the stepApiNamesList input parameter.
```

**Correct approach**: Do not declare `stepApiNamesList` as an input on the evaluator flow. Do not pass it in the background step `inputParameters`. When `stepApiNamesList` is omitted from the standard action call, `getPreviousRelaRecDetails` returns details for all previous steps in the orchestration instance, which is the correct behaviour for most evaluator flows.

### Constraint 3 — Formula variables cannot reference $Flow.OrchestrationInstanceId

A Text formula variable in an `AutoLaunchedFlow` referencing `{!$Flow.OrchestrationInstanceId}` will fail at deployment:

```text
field integrity exception: "formulaVarName" refers to an element:
"$Flow.OrchestrationInstanceId", which doesn't exist.
```

This confirms `$Flow.OrchestrationInstanceId` is fully inaccessible in `AutoLaunchedFlow` regardless of how it is referenced.

### Constraint 4 — storeOutputAutomatically=true Apex outputs are scalar, not loopable

When a Flow `<actionCalls>` element calls an Apex `@InvocableMethod` with `<storeOutputAutomatically>true</storeOutputAutomatically>`, the platform stores output as **scalar properties** on the action element — NOT as a collection. Attempting to use a `<loops>` element to iterate over the action output fails at deployment:

```text
"Evaluate_Levels isn't a collection element"
```

**Correct approach**: Access output fields directly as `ActionName.fieldName` in assignment elements:

```xml
<assignmentItems>
    <assignToReference>varCanAutoApprove</assignToReference>
    <operator>Assign</operator>
    <value><elementReference>Evaluate_Levels.canAutoApprove</elementReference></value>
</assignmentItems>
```

Do NOT wrap the Apex action output in a `<loops>` element when using `storeOutputAutomatically=true`.

Note: `getPreviousRelaRecDetails` wrapper (`ApprovalPreviousRelatedRecordDetails`) returns `List<List<SObject>>` — this IS a collection and correctly uses a `<loops>` element because the output is an SObject collection, not a scalar Apex invocable output.

### Constraint 5 — getPreviousRelaRecDetails returns empty collection (not null) when no prior submission

When no previous submission exists for the orchestration instance, `getPreviousRelaRecDetails` returns an **empty collection** — not null. A Flow `IsNull` check against the `storeOutputAutomatically=true` collection reference always evaluates to non-null (empty collection ≠ null), making the no-prior-submission branch permanently unreachable.

**Wrong pattern** (IsNull on collection output — dead code):
```xml
<decisions>
    <name>Decision_Previous_Data_Found</name>
    <rules>
        <conditions>
            <leftValueReference>Get_Previous_Related_Record_Details</leftValueReference>
            <operator>IsNull</operator>
            <rightValue><booleanValue>false</booleanValue></rightValue>
        </conditions>
        <!-- This rule ALWAYS fires even when collection is empty -->
    </rules>
</decisions>
```

**Correct pattern** — loop first, then check captured scalar for null:
```text
Get_Previous_Related_Record_Details (Apex action, storeOutputAutomatically=true)
  ↓
Loop_Previous_Records
  nextValue → Capture_Previous_Value (assign varPreviousLevel = Loop_var.RLM_Approval_Level__c)
    → back to loop
  noMoreValues → Decision_Is_Previous_Found
    rule: varPreviousLevel IsNull = false → Evaluate_Levels
    default → Set_No_Previous_Reason (varCanAutoApprove = false)
```

The scalar variable (`varPreviousLevel`) is null when the loop iterates zero times — that null check is reliable.

## Previous Related Record Details Apex Action

Use an Apex wrapper around the Salesforce standard invocable action:

```text
getPreviousRelaRecDetails
```

Inputs: both optional, set conditionally on the standard action

| Input | Required | Notes |
|---|---|---|
| `flowOrchestrationInstanceId` | No | Set only when non-blank. When called from a background step, leave blank — platform resolves context automatically. |
| `stepApiNamesList` | No | Set only when non-null/non-empty. Cannot be passed from a background step inputParameter (collection type — deploy error). Leave blank to return all previous step details. |

Output:

| Output | Purpose |
|---|---|
| previousRelatedRecordDetails | Previous submission related records in the current orchestration instance |

## Apex Wrapper Standard

Use the Apex template in:

```text
templates/ApprovalPreviousRelatedRecordDetails.cls
```

Key implementation rules:

- `flowOrchestrationInstanceId` and `stepApiNamesList` are `@InvocableVariable(required=false)` on `FlowInputs`
- Set each parameter on the standard action **only when provided** (non-blank / non-empty guard)
- When called from a background step evaluator flow: neither is passed — platform resolves orchestration context automatically
- When called from non-background-step contexts: both can be passed explicitly
- Handle empty result safely — return empty list, not null
- Catch all exceptions and return empty list (fail-safe → manual approval)
- Log failures with `System.debug(LoggingLevel.WARN/ERROR, ...)` at minimum

## Autolaunched Flow Standard

Recommended Flow:

```text
<auto-approval-flow-api-name>
```

Inputs — DO NOT include `varFlowOrchestrationInstanceId` or `varStepApiNamesList`:

| Variable | Type | Required | Notes |
|---|---|---|---|
| current approval fields | relevant types | Yes | e.g. varCurrentRoutingValue (Number) |

Collections and orchestration ID variables cannot be passed via background step. Pass only scalar values that the evaluator needs from the current record state.

Outputs:

| Variable | Type | Role |
|---|---|---|
| varCanAutoApprove | Boolean | Target approval step auto-approve decision |
| varEvaluationReason | Text | Diagnostic reason |
| varManualReviewReason | Text | Why manual approval is required |

Flow steps:

```text
1. Receive current approval context.
2. Call Apex action: Get Previous Related Record Details.
3. If no previous data, set varCanAutoApprove = false.
4. Compare current vs previous values.
5. If only non-material changes exist, set true.
6. If material changes exist, set false.
7. Return Boolean to approval workflow.
```

## Fail-Safe Rule

For production governance:

```text
When in doubt, manual approval.
```

Set `varCanAutoApprove = false` for:

- Apex action failure
- no previous data
- unexpected record type
- parse error
- missing critical current value
- unsupported comparison scenario
- currency mismatch
- line matching ambiguity

## Logging Standard

> **Org-neutral:** Do NOT hardcode a custom logging object. Confirm the target org has the object before adding DML. Ask the user which logging mechanism their org uses — custom object, platform event, or email alert.

If the org has no logging object and the user agrees to create one, suggested object API name: `Approval_Auto_Approval_Evaluation__c` (TODO_VERIFY_IN_ORG)

Suggested fields:

| Field | Purpose |
|---|---|
| Source_Record_Id__c | Quote/order/custom source record |
| Flow_Orchestration_Instance_Id__c | Approval orchestration instance |
| Target_Step_Api_Name__c | Approval step being evaluated |
| Can_Auto_Approve__c | Boolean result |
| Evaluation_Reason__c | Human-readable reason |
| Manual_Review_Reason__c | Why manual review required |
| Previous_Data_Found__c | Whether previous details were returned |
| Error_Message__c | Failure details |
| Evaluated_At__c | Timestamp |

Only add persistent logging if DML is allowed, the object exists in the org, and governance accepts it.

## Testing Matrix

| Test | Expected |
|---|---|
| First submission | Manual approval required |
| Resubmission with no material changes | Auto-approval allowed |
| Discount increased | Manual approval |
| Discount decreased | Auto-approval if policy allows |
| Approval-sensitive field unchanged | Auto-approval |
| Approval-sensitive field worsened | Manual approval |
| Related line added | Manual approval |
| Related line removed | Manual approval unless non-material |
| Previous data missing | Manual approval |
| Apex action fails | Manual approval |
| Background step not complete | Target step should not start |
| Boolean output false | Manual approval |
| Boolean output true | Target step auto-approves |

## Common Misconfigurations

| Symptom | Likely cause |
|---|---|
| Target approval step never starts | Background step API name mismatch |
| Manual review still required | Boolean output false or not mapped in Flow Builder UI |
| Apex returns no data | No previous submission exists for this orchestration instance |
| Auto-approval too broad | evaluation logic ignores material fields |
| Auto-approval never happens | flow returns false on no-data or comparison mismatch |
| Flow fault | Apex action result handling assumes results[0] exists |
| Previous lines mismatch | comparing by list order instead of stable key |
| Deploy error: type mismatch on flowOrchestrationInstanceId | Attempted to pass `$Flow.OrchestrationInstanceId` from orchestration flow to evaluator flow input — remove it, the standard action resolves context automatically |
| Deploy error: "Enter a valid name for stepApiNamesList" | Attempted to pass a Text Collection from background step to evaluator flow input — collections cannot be passed via background step inputParameters |
| Deploy error: formula refers to element that doesn't exist | Used `{!$Flow.OrchestrationInstanceId}` in a formula in an AutoLaunchedFlow — it does not exist in that flow type |
| Deploy error: "ActionName isn't a collection element" | Used `<loops>` to iterate over a `storeOutputAutomatically=true` Apex action output — scalar, not a collection; access fields directly as `ActionName.fieldName` |
| No-previous-submission branch never reached | Used `IsNull` check on `storeOutputAutomatically=true` collection from `getPreviousRelaRecDetails` — empty collection is non-null; use post-loop scalar null check instead |
| Auto-approval decision ignored | "Set custom logic for auto-approvals" not wired in Flow Builder UI — cannot be set in Flow XML; must be configured in Flow Builder after every deployment |

## Relationship to Smart Approval

Smart Approval and Rule-Based Auto-Approvals are complementary.

| Capability | Smart Approval | Rule-Based Auto-Approval |
|---|---|---|
| Platform history matching | Yes | Uses custom logic |
| Field-level materiality | Limited/config-dependent | Yes |
| Custom comparison | No/limited | Yes |
| Requires custom Flow/Apex | No | Yes |
| Best for | same approver/same condition reuse | business-specific resubmission logic |

Use Smart Approval for broad resubmission optimization and Rule-Based Auto-Approvals for precise business policy.
