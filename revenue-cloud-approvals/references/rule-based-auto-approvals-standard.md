# Rule-Based Auto-Approvals Standard

Source: https://help.salesforce.com/s/articleView?id=ind.approvals_define_custom_logic_auto_approvals.htm&type=5 (verified 2026-06-12)

## Rule-Based Auto-Approvals Standard

Use Rule-Based Auto-Approvals when the business needs custom field-level comparison on resubmissions. This complements Smart Approval by allowing an autolaunched Flow and Apex action to compare the current submission against the previously submitted record details.

Do not enter this pattern merely because the user says "Smart Approval." Use this section only after the user chooses **Set custom logic for auto-approvals** or explicitly requests custom comparison logic.

Load:

```text
references/rule-based-auto-approvals.md
templates/ApprovalPreviousRelatedRecordDetails.cls
templates/AutoApprovalCustomLogicDecision.cls
templates/rule-based-auto-approval-flow-template.md
```

### Standard Architecture

```text
ApprovalWorkflow Stage
  ↓
Background Step before target approval step
  ↓
Custom Autolaunched Flow
  ↓
Apex Action: getPreviousRelaRecDetails wrapper
  ↓
Compare previous vs current submitted details
  ↓
Return Boolean varCanAutoApprove
  ↓
Target Approval Step uses Set custom logic for auto-approvals
```

### Apex Output Contract

Two valid patterns depending on how the Flow consumes the output:

**Pattern A — Flat output, consumed via `storeOutputAutomatically=true` scalar properties**

Use when the Flow reads output fields directly from the action element (no loop):

```apex
public static List<Output> evaluate(List<Input> inputs)
```

Flow accesses fields as `ActionName.canAutoApprove` directly. Do NOT use a `<loops>` element — `storeOutputAutomatically=true` Apex outputs are scalar, not collections. Using a loop causes:
```text
"ActionName isn't a collection element"
```

**Pattern B — Nested output, consumed via loop (collection outputs)**

Use when the Apex action returns a true collection that the Flow must iterate:

```apex
public static List<List<Output>> evaluate(List<Input> inputs)
```

The outer list maps to each Flow/Approval request input; the inner list contains output rows. `ApprovalPreviousRelatedRecordDetails.getPreviousRelaRecDetails` correctly returns `List<List<SObject>>` — preserve this shape because its output IS a collection of SObject records to loop over.

**Choosing between patterns:**

| Scenario | Pattern |
|---|---|
| Boolean decision result (canAutoApprove + reason strings) | A — flat, scalar access |
| SObject collection retrieval (previous record details) | B — nested, loop over records |
| Multiple discrete output rows per input | B — nested |

The Boolean consumed by the target approval step must be an `@InvocableVariable` on the `Output` class, such as `canAutoApprove`, in either pattern.

### Required Configuration

1. Create the Apex wrapper for standard action `getPreviousRelaRecDetails`.
   - Declare `flowOrchestrationInstanceId` (String) and `stepApiNamesList` (List\<String\>) as `@InvocableVariable(required=false)` on `FlowInputs`.
   - Call `Invocable.Action.createStandardAction('getPreviousRelaRecDetails')`.
   - Set `flowOrchestrationInstanceId` on the action **only when non-blank** (`if (!String.isBlank(...))`).
   - Set `stepApiNamesList` on the action **only when non-null and non-empty**.
   - When called from a background step evaluator flow: neither is passed by the flow (platform constraints — see Known Platform Constraints table below). The standard action resolves the orchestration context automatically.
   - When called from non-background-step contexts: both can be provided explicitly.
2. Create a custom AutoLaunchedFlow (`processType: AutoLaunchedFlow`) to call the Apex action and evaluate rules.
   - The evaluator flow must NOT have `flowOrchestrationInstanceId` or `stepApiNamesList` as input variables.
   - Only scalar (non-collection) inputs can be passed from the orchestration background step.
3. Add a Background Step before the target approval step in the orchestration flow.
   - Pass only scalar values (e.g. `currentRoutingValue`) from the orchestration flow to the evaluator flow inputs.
   - Do NOT reference `$Flow.OrchestrationInstanceId` in the background step inputParameters.
4. Run the background step as Automated Process User.
5. Configure the target approval step in Flow Builder UI (cannot be done via Flow XML):
   - Start when the background step is marked Complete.
   - Reference the background step API name.
   - Select Set custom logic for auto-approvals.
   - Map Auto-Approve Step to the Boolean output from the evaluation Flow.

### Known Platform Constraints (Background Step → AutoLaunchedFlow)

These errors occur if the constraints below are violated:

| Constraint | Error at deploy | Correct approach |
|---|---|---|
| `$Flow.OrchestrationInstanceId` passed as background step input | `type for the input parameter doesn't match the type for the assigned value` | Remove it — standard action resolves context automatically |
| Collection input (Text Collection) passed from background step | `Enter a valid name for the stepApiNamesList input parameter` | Remove collection inputs from evaluator flow; omit from background step |
| Formula in AutoLaunchedFlow references `$Flow.OrchestrationInstanceId` | `refers to an element which doesn't exist` | Not accessible in AutoLaunchedFlow — use only in ApprovalWorkflow flows |
| "Set custom logic for auto-approvals" configured in Flow XML | Parameter not found or ignored at deploy | Must be configured via Flow Builder UI — not exposed in Flow XML |

### Fail-Safe Rule

Default to manual approval:

```text
varCanAutoApprove = false
```

Set true only after all custom comparison rules pass.

### When to Use

Use this pattern for:

- field-level materiality comparisons
- payment terms changes
- discount increase/decrease logic
- line-level comparison
- legal term hash comparison
- product mix comparison
- custom resubmission governance

### When Not to Use

Do not auto-approve when:

- previous submission data is unavailable
- Apex action fails
- material values increased/worsened
- approval-relevant related records changed
- comparison logic cannot confidently determine safety
