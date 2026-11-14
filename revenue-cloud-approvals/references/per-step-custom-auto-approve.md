# Per-Step Custom Auto-Approve Pattern (Apex Evaluator)

> **Examples in this file are illustrative.** Object, field, group and approver names (e.g. Quote, discount, Finance, Manager) are placeholders; substitute the target org's values and mark anything unconfirmed `TODO_VERIFY_IN_ORG`.

Use this pattern for resubmission auto-approval where per-step eligibility is determined by Apex logic comparing prior `ApprovalWorkItem` decisions against the current approval level — without using platform Smart Approval.

> **Key principle:** Auto-approve eligibility is computed per-step by Apex (querying `ApprovalWorkItem` by step label) and surfaced as per-step Boolean flow variables. Step entry conditions remain standard routing-only (level check + predecessor decision). Booleans feed the stage exit formula and final status formula only.

---

## Architecture: 4-Stage ApprovalWorkflow

```
Stage_GetDetails           → GetDetails sub (retrieves approval-driving field)
Stage_EvaluateAutoApproval → Evaluator sub (Apex per-step booleans)
Stage_Approvals            → 3 stepApproval steps (standard entry conditions)
Stage_Finalize             → UpdateStatus sub (quoteStatusFinal drives status)
```

---

## Component 1: GetDetails Subflow (AutoLaunchedFlow)

Simple: queries the target object for the approval-driving field only. No ApprovalWorkItem logic here.

```xml
<recordLookups>
    <name>Get_TargetObject</name>
    <object><TargetObject></object>
    <filters>
        <field>Id</field>
        <operator>EqualTo</operator>
        <value><elementReference>recordId</elementReference></value>
    </filters>
    <getFirstRecordOnly>true</getFirstRecordOnly>
    <outputAssignments>
        <assignToReference>varApprovalLevel</assignToReference>
        <field><ApprovalLevelField></field>
    </outputAssignments>
    <faultConnector><targetReference>Set_Fault_Default</targetReference></faultConnector>
</recordLookups>
```

Fault handler sets `varApprovalLevel = -1` (sentinel) and captures `$Flow.FaultMessage`.

Output: `varApprovalLevel` (Number, isOutput: true).

---

## Component 2: Evaluator Subflow (AutoLaunchedFlow)

Runs `ApprovalPreviousRelatedRecordDetails` (Revenue Cloud built-in Apex action) to retrieve the target object record from the prior approval submission. Captures the previous approval level. Passes `quoteId` + `currentLevel` + `previousLevel` to the Apex evaluator class.

### Flow structure

```
Init_Defaults (all booleans = false)
  → Get_Previous_Related_Record_Details  (ApprovalPreviousRelatedRecordDetails, fault → Set_Fault_FailSafe)
      → Loop_Previous_Records
          → Capture_Previous_Level (last value wins)
          → Loop_Previous_Records (next)
      → Decision_Is_Previous_Found
          → Previous exists: Evaluate_Levels (Apex, fault → Set_Fault_FailSafe)
              → Assign_From_Apex
          → No previous: Set_No_Previous_Reason (all false — first submission)
```

### ApprovalPreviousRelatedRecordDetails action

```xml
<actionCalls>
    <name>Get_Previous_Related_Record_Details</name>
    <actionName>ApprovalPreviousRelatedRecordDetails</actionName>
    <actionType>apex</actionType>
    <dataTypeMappings>
        <typeName>U__output</typeName>
        <typeValue><TargetObject></typeValue>    <!-- e.g. Quote -->
    </dataTypeMappings>
    <faultConnector><targetReference>Set_Fault_FailSafe</targetReference></faultConnector>
    <flowTransactionModel>CurrentTransaction</flowTransactionModel>
    <storeOutputAutomatically>true</storeOutputAutomatically>
</actionCalls>
```

Loop captures `<ApprovalLevelField>` from each prior record into `varPreviousApprovalLevel` (Number).

### Apex evaluator invocation

```xml
<actionCalls>
    <name>Evaluate_Levels</name>
    <actionName><ApexEvaluatorClassName></actionName>    <!-- e.g. SmartApprovalByAg2Evaluator -->
    <actionType>apex</actionType>
    <inputParameters>
        <name>quoteId</name>       <!-- TODO_VERIFY: match Apex @InvocableVariable name -->
        <value><elementReference>quoteId</elementReference></value>
    </inputParameters>
    <inputParameters>
        <name>currentApprovalLevel</name>
        <value><elementReference>varCurrentApprovalLevel</elementReference></value>
    </inputParameters>
    <inputParameters>
        <name>previousApprovalLevel</name>
        <value><elementReference>varPreviousApprovalLevel</elementReference></value>
    </inputParameters>
    <faultConnector><targetReference>Set_Fault_FailSafe</targetReference></faultConnector>
    <flowTransactionModel>CurrentTransaction</flowTransactionModel>
    <storeOutputAutomatically>true</storeOutputAutomatically>
</actionCalls>
```

### Evaluator subflow variables

Inputs: `quoteId` (String), `varCurrentApprovalLevel` (Number).
Outputs: `varCanAutoApprove<Level1>`, `varCanAutoApprove<Level2>`, `varCanAutoApprove<Level3>` (Boolean, isOutput: true, default: false).
Internal: `varPreviousApprovalLevel` (Number).

---

## Component 3: Apex Evaluator Class

Receives `recordId`, `currentApprovalLevel`, `previousApprovalLevel`. If `currentLevel <= previousLevel`, queries `ApprovalWorkItem` by `FlowOrchestrationWorkItem.Label` (step label) to find the latest prior decision per step. Returns per-step Boolean outputs.

```apex
public without sharing class <ApexEvaluatorClassName> {
    @InvocableMethod(label='Evaluate Custom Auto-Approval')
    public static List<Output> evaluate(List<Input> inputs) {
        List<Output> responses = new List<Output>();
        if (inputs == null || inputs.isEmpty()) {
            responses.add(new Output());
            return responses;
        }
        for (Input req : inputs) {
            Output result = new Output();
            // Default: all false (require human approval)
            result.canAutoApprove<Level1> = false;
            result.canAutoApprove<Level2> = false;
            result.canAutoApprove<Level3> = false;

            if (req.currentApprovalLevel != null && req.previousApprovalLevel != null
                    && req.recordId != null
                    && req.currentApprovalLevel <= req.previousApprovalLevel) {
                List<ApprovalWorkItem> workItems = [
                    SELECT Status, FlowOrchestrationWorkItem.Label
                    FROM ApprovalWorkItem
                    WHERE RelatedRecordId = :req.recordId AND Status IN ('Approved', 'Rejected')
                    ORDER BY CreatedDate DESC
                ];
                // Latest-wins map: step label → most recent status
                Map<String, String> latestByStep = new Map<String, String>();
                for (ApprovalWorkItem wi : workItems) {
                    String lbl = wi.FlowOrchestrationWorkItem?.Label;
                    if (!String.isBlank(lbl) && !latestByStep.containsKey(lbl)) {
                        latestByStep.put(lbl, wi.Status);
                    }
                }
                result.canAutoApprove<Level1> = latestByStep.get('<Level1 step label>') == 'Approved';
                result.canAutoApprove<Level2> = latestByStep.get('<Level2 step label>') == 'Approved';
                result.canAutoApprove<Level3> = latestByStep.get('<Level3 step label>') == 'Approved';
            }
            responses.add(result);
        }
        return responses;
    }

    public class Input {
        @InvocableVariable(label='Record ID' required=true) public Id recordId;
        @InvocableVariable(label='Current Approval Level' required=true) public Decimal currentApprovalLevel;
        @InvocableVariable(label='Previous Approval Level') public Decimal previousApprovalLevel;
    }
    public class Output {
        @InvocableVariable(label='Can Auto Approve <Level1>') public Boolean canAutoApprove<Level1> = false;
        @InvocableVariable(label='Can Auto Approve <Level2>') public Boolean canAutoApprove<Level2> = false;
        @InvocableVariable(label='Can Auto Approve <Level3>') public Boolean canAutoApprove<Level3> = false;
    }
}
```

**Step label matching:** The Apex uses `FlowOrchestrationWorkItem.Label` (which equals the `<label>` element on the `stageStep` in the ApprovalWorkflow XML). Labels must match exactly — case-sensitive, space-sensitive. Set the step `<label>` in the flow XML consistently with what the Apex expects.

**currentLevel <= previousLevel guard:** Auto-approve is only considered when the approval level has not increased. If the level increased, all steps require fresh human approval. If `previousApprovalLevel` is null (first submission), all outputs default to false — human approval required.

---

## Component 4: Main ApprovalWorkflow (4 stages)

### Stage 2 — EvaluateAutoApproval step

```xml
<orchestratedStages>
    <name>Stage_EvaluateAutoApproval</name>
    <exitConditionLogic>and</exitConditionLogic>
    <stageSteps>
        <name>EvaluateAutoApproval_Step</name>
        <actionName><EvaluatorSubflowApiName></actionName>
        <actionType>stepBackground</actionType>
        <inputParameters>
            <name>quoteId</name>
            <value><elementReference>recordId</elementReference></value>
        </inputParameters>
        <inputParameters>
            <name>varCurrentApprovalLevel</name>
            <value><elementReference>varApprovalLevel</elementReference></value>
        </inputParameters>
        <outputParameters>
            <assignToReference>varCanAutoApprove<Level1></assignToReference>
            <name>varCanAutoApprove<Level1></name>
        </outputParameters>
        <outputParameters>
            <assignToReference>varCanAutoApprove<Level2></assignToReference>
            <name>varCanAutoApprove<Level2></name>
        </outputParameters>
        <outputParameters>
            <assignToReference>varCanAutoApprove<Level3></assignToReference>
            <name>varCanAutoApprove<Level3></name>
        </outputParameters>
        <stepSubtype>BackgroundStep</stepSubtype>
    </stageSteps>
</orchestratedStages>
```

### Stage 3 — Approvals: step entry conditions

Step entry conditions are **standard routing only** — level check and predecessor decision. Do NOT put auto-approve booleans in step entry conditions. This keeps conditions clean and avoids Flow Builder validation warnings from complex condition logic.

```xml
<!-- Level 1 step (e.g. Manager Approval) -->
<entryConditionLogic>and</entryConditionLogic>
<entryConditions>
    <leftValueReference>varApprovalLevel</leftValueReference>
    <operator>GreaterThanOrEqualTo</operator>
    <rightValue><numberValue>1.0</numberValue></rightValue>
</entryConditions>

<!-- Level 2 step (e.g. Director Approval) -->
<entryConditionLogic>and</entryConditionLogic>
<entryConditions>
    <leftValueReference>varApprovalLevel</leftValueReference>
    <operator>GreaterThanOrEqualTo</operator>
    <rightValue><numberValue>2.0</numberValue></rightValue>
</entryConditions>
<entryConditions>
    <leftValueReference><Level1>Step.Outputs.approvalDecision</leftValueReference>
    <operator>EqualTo</operator>
    <rightValue><stringValue>Approve</stringValue></rightValue>
</entryConditions>

<!-- Level 3 step (e.g. VP Approval) -->
<!-- same pattern: level >= 3 AND Level2.decision == 'Approve' -->
```

### Stage 3 — Formulas

Auto-approve booleans are used **only in formulas** (stage exit and final status). Formulas may reference flow variables and step outputs — formula references are allowed here.

#### isLevel2Required

```
AND(
  {!varApprovalLevel} >= 2,
  OR({!<Level1>Step.Outputs.approvalDecision} == 'Approve', {!varCanAutoApprove<Level1>})
)
```

#### isLevel3Required

```
AND(
  {!varApprovalLevel} >= 3,
  OR({!<Level2>Step.Outputs.approvalDecision} == 'Approve', {!varCanAutoApprove<Level2>})
)
```

#### IsApprovalsStageComplete (stage exit formula — required on all approval stages)

```
AND(
  OR(NOT({!varApprovalLevel} >= 1), NOT(ISBLANK({!<Level1>Step.Outputs.approvalDecision})), {!varCanAutoApprove<Level1>}),
  OR(NOT({!isLevel2Required}), NOT(ISBLANK({!<Level2>Step.Outputs.approvalDecision})), {!varCanAutoApprove<Level2>}),
  OR(NOT({!isLevel3Required}), NOT(ISBLANK({!<Level3>Step.Outputs.approvalDecision})), {!varCanAutoApprove<Level3>})
)
```

Per clause: `OR(step not required, step has a decision, step was auto-approved by evaluator)`.

#### finalStatus formula

```
IF(AND(
  IF({!varApprovalLevel} >= 1, OR({!<Level1>Step.Outputs.approvalDecision} == 'Approve', {!varCanAutoApprove<Level1>}), true),
  IF({!isLevel2Required}, OR({!<Level2>Step.Outputs.approvalDecision} == 'Approve', {!varCanAutoApprove<Level2>}), true),
  IF({!isLevel3Required}, OR({!<Level3>Step.Outputs.approvalDecision} == 'Approve', {!varCanAutoApprove<Level3>}), true)
), 'Approved', 'Rejected')
```

### Main flow variables

Add one Boolean variable per step (default false):

```xml
<variables>
    <name>varCanAutoApprove<Level1></name>
    <dataType>Boolean</dataType>
    <isCollection>false</isCollection>
    <isInput>false</isInput>
    <isOutput>false</isOutput>
    <value><booleanValue>false</booleanValue></value>
</variables>
<!-- repeat for Level2, Level3 -->
```

---

## Deployment Order

1. Apex evaluator class
2. GetDetails subflow
3. Evaluator subflow (references Apex class)
4. UpdateStatus subflow
5. Main ApprovalWorkflow (references all subflows)

---

## INFO Messages at Deployment (expected, not errors)

These appear for any ApprovalWorkflow with `assigneeType: User/Group/Queue`:

- `"Because the Automated Process User has no valid email address..."` → org-level setup. Fix: set Automated Process User email in Process Automation Settings.
- `"You can't package an orchestration that contains a step with assignee type set to User, Group, or Queue."` → packaging restriction only. Not deployable in packages, but fine for org-to-org deployment.

These warnings appear for ALL ApprovalWorkflow flows using User assignees — they are not unique to this pattern.

---

## Known Constraint

With standard entry conditions (no auto-approve skip), approval steps create work items even when the evaluator returns `canAutoApprove = true`. The `varCanAutoApprove` booleans affect:
- **When the stage exits** (via `IsApprovalsStageComplete`) — if a step was auto-approved and no other steps are pending, the stage exits immediately
- **What final status is set** (via `finalStatus`) — auto-approved steps count as Approved in the status formula

The Apex evaluator pattern does NOT prevent work item creation. If preventing work item creation is required (true step skip), use entry conditions to exclude the step when `varCanAutoApprove = true`.

---

## Apex Test Pattern

```apex
// Inject mock work items
SmartApprovalByAg2Evaluator.workItemsForTest = new List<ApprovalWorkItem>();
// Add mock records with FlowOrchestrationWorkItem.Label values for each step
// Test: currentLevel <= previousLevel path, currentLevel > previousLevel path, null inputs
```
