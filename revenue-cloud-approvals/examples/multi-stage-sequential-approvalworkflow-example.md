# Worked Example: Sequential Approval With One Stage Per Level (ApprovalWorkflow)

> **Example only.** Names are placeholders. Use when Pre-Flight row 11 chose "one stage per level or phase". The structure below was tested in an org: routing, stage-by-stage advance, rejection skipping later stages, auto-approve when nothing is required, and Smart Approval resubmission across stages.

Scenario: level 1 -> `Level1_Queue`; level 2 -> then `Level2_Queue`; level 3 -> then `Level3_Queue`. Routing number from a record field via a gather subflow (`ApprovalLevel`). Outcome Decision after the last approval stage.

## Formulas (flow level)
```xml
<formulas>
    <name>ApprovalLevelSafe</name>
    <dataType>Number</dataType>
    <expression>IF(ISBLANK({!QueryApprovalData.Outputs.ApprovalLevel}), 0, {!QueryApprovalData.Outputs.ApprovalLevel})</expression>
    <scale>0</scale>
</formulas>
<formulas>
    <name>isLevel2Required</name>
    <dataType>Boolean</dataType>
    <expression>AND({!ApprovalLevelSafe} &gt;= 2, {!Level1_Approval.Outputs.approvalDecision} = &quot;Approve&quot;)</expression>
</formulas>
<formulas>
    <name>isLevel3Required</name>
    <dataType>Boolean</dataType>
    <expression>AND({!ApprovalLevelSafe} &gt;= 3, {!Level2_Approval.Outputs.approvalDecision} = &quot;Approve&quot;)</expression>
</formulas>
<formulas>
    <name>IsLevel1StageComplete</name>
    <dataType>Boolean</dataType>
    <expression>OR({!ApprovalLevelSafe} &lt; 1, NOT(ISBLANK({!Level1_Approval.Outputs.approvalDecision})))</expression>
</formulas>
<formulas>
    <name>IsLevel2StageComplete</name>
    <dataType>Boolean</dataType>
    <expression>OR(NOT({!isLevel2Required}), NOT(ISBLANK({!Level2_Approval.Outputs.approvalDecision})))</expression>
</formulas>
<formulas>
    <name>IsLevel3StageComplete</name>
    <dataType>Boolean</dataType>
    <expression>OR(NOT({!isLevel3Required}), NOT(ISBLANK({!Level3_Approval.Outputs.approvalDecision})))</expression>
</formulas>
<formulas>
    <name>IsAnyRejected</name>
    <dataType>Boolean</dataType>
    <expression>OR({!Level1_Approval.Outputs.approvalDecision} = &quot;Reject&quot;, {!Level2_Approval.Outputs.approvalDecision} = &quot;Reject&quot;, {!Level3_Approval.Outputs.approvalDecision} = &quot;Reject&quot;)</expression>
</formulas>
```

## Stages (each connected to the next; approval stage 3 connects to the outcome Decision)
```xml
<orchestratedStages>
    <name>Level1_Stage</name>
    <label>Level 1 Approval</label>
    <locationX>0</locationX>
    <locationY>0</locationY>
    <connector><targetReference>Level2_Stage</targetReference></connector>
    <exitConditionLogic>and</exitConditionLogic>
    <exitConditions>
        <conditionType>ExitCondition</conditionType>
        <leftValueReference>IsLevel1StageComplete</leftValueReference>
        <operator>EqualTo</operator>
        <rightValue><booleanValue>true</booleanValue></rightValue>
    </exitConditions>
    <stageSteps>
        <name>Level1_Approval</name>
        <actionName>standard_approvals__EvaluateApproval</actionName>
        <actionType>stepApproval</actionType>
        <assignees><assignee><stringValue>Level1_Queue</stringValue></assignee><assigneeType>Queue</assigneeType></assignees>
        <canAssigneeEdit>false</canAssigneeEdit>
        <entryConditionLogic>and</entryConditionLogic>
        <entryConditions>
            <conditionType>EntryCondition</conditionType>
            <leftValueReference>QueryApprovalData.Outputs.ApprovalLevel</leftValueReference>
            <operator>GreaterThanOrEqualTo</operator>
            <rightValue><numberValue>1.0</numberValue></rightValue>
        </entryConditions>
        <exitConditionLogic>and</exitConditionLogic>
        <inputParameters><name>ActionInput__RecordId</name><value><elementReference>recordId</elementReference></value></inputParameters>
        <inputParameters><name>ActionInput__ApprovalChainName</name><value><stringValue>Business_Domain_Approval_Chain</stringValue></value></inputParameters>
        <inputParameters><name>ActionInput__CanUseSmartApproval</name><value><stringValue>true</stringValue></value></inputParameters>
        <label>Level 1 Approval</label>
        <outputConfigParams><name>approvalDecision</name><value xsi:nil="true"/></outputConfigParams>
        <requiresAsyncProcessing>false</requiresAsyncProcessing>
        <runAsUser>false</runAsUser>
        <shouldLock>false</shouldLock>
        <stepSubtype>ApprovalStep</stepSubtype>
    </stageSteps>
</orchestratedStages>
<orchestratedStages>
    <name>Level2_Stage</name>
    <label>Level 2 Approval</label>
    <locationX>0</locationX>
    <locationY>0</locationY>
    <connector><targetReference>Level3_Stage</targetReference></connector>
    <exitConditionLogic>and</exitConditionLogic>
    <exitConditions>
        <conditionType>ExitCondition</conditionType>
        <leftValueReference>IsLevel2StageComplete</leftValueReference>
        <operator>EqualTo</operator>
        <rightValue><booleanValue>true</booleanValue></rightValue>
    </exitConditions>
    <stageSteps>
        <name>Level2_Approval</name>
        <actionName>standard_approvals__EvaluateApproval</actionName>
        <actionType>stepApproval</actionType>
        <assignees><assignee><stringValue>Level2_Queue</stringValue></assignee><assigneeType>Queue</assigneeType></assignees>
        <canAssigneeEdit>false</canAssigneeEdit>
        <entryConditionLogic>and</entryConditionLogic>
        <entryConditions>
            <conditionType>EntryCondition</conditionType>
            <leftValueReference>QueryApprovalData.Outputs.ApprovalLevel</leftValueReference>
            <operator>GreaterThanOrEqualTo</operator>
            <rightValue><numberValue>2.0</numberValue></rightValue>
        </entryConditions>
        <entryConditions>
            <conditionType>EntryCondition</conditionType>
            <leftValueReference>Level1_Approval.Outputs.approvalDecision</leftValueReference>
            <operator>EqualTo</operator>
            <rightValue><stringValue>Approve</stringValue></rightValue>
        </entryConditions>
        <exitConditionLogic>and</exitConditionLogic>
        <inputParameters><name>ActionInput__RecordId</name><value><elementReference>recordId</elementReference></value></inputParameters>
        <inputParameters><name>ActionInput__ApprovalChainName</name><value><stringValue>Business_Domain_Approval_Chain</stringValue></value></inputParameters>
        <inputParameters><name>ActionInput__CanUseSmartApproval</name><value><stringValue>true</stringValue></value></inputParameters>
        <label>Level 2 Approval</label>
        <outputConfigParams><name>approvalDecision</name><value xsi:nil="true"/></outputConfigParams>
        <requiresAsyncProcessing>false</requiresAsyncProcessing>
        <runAsUser>false</runAsUser>
        <shouldLock>false</shouldLock>
        <stepSubtype>ApprovalStep</stepSubtype>
    </stageSteps>
</orchestratedStages>
```

Repeat the same shape for `Level3_Stage` (entry: level >= 3 and `Level2_Approval.Outputs.approvalDecision = "Approve"`; connector to the outcome Decision), then add the outcome Decision (`IsAnyRejected`) and the `Approved_Outcome` / `Rejected_Outcome` stages exactly as in `serial-tiered-approvalworkflow-example.md`.

## Behaviour to expect
- Only the first level's work item exists at submission; each later level appears only after the previous one is approved.
- A rejection at any level: later steps never start, their stage formulas evaluate true, and the process goes to the outcome Decision and the Rejected stage.
- Any extra approval either shares a stage with other steps or has its own stage before or after the chain (Pre-Flight row 10). It is **not** fully parallel with the whole chain: later stages wait for the whole earlier stage.
- **Grouped variant (verified):** put the extra approvals in the same stage as the first level, with that stage's exit formula `AND(IsLevel1Done, IsExtraADone, IsExtraBDone)`. Level 2 then starts only after Level 1 and the extra approvals are all complete, nothing is withdrawn, and a rejection in the stage waits for the other steps in it before the outcome Decision.
- Never leave a step out of its stage's exit formula: a stage that exits early withdraws its pending steps.
- Smart Approval on resubmission after a rejection reuses prior approvals in earlier stages and re-assigns the rejected step.
