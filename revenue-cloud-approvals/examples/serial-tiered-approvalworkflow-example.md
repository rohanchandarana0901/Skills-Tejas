# Worked Example: Serial Tiered Quote Approval (ApprovalWorkflow)

Scenario: Level 1 → Manager queue; Level 2 → Manager then Director queue; Level 3+ → Manager, Director, then VP queue. Serial, Smart Approval enabled, approval level read from `Quote.RLM_Approval_Level__c`.

Structure follows the skill's Required Process Skeleton: Gather data → Approvals → Decision → Approved / Rejected outcome stage. The same structure was tested in a target org (routing, serial order, rejection, auto-approve, Smart Approval resubmission); this exact file was not deployed as written. Complete the Completeness Gate in SKILL.md before treating a derived build as verified. The shape of an earlier revision (a Decision element before the approvals stage, one multi-input Finalize stage) is an anti-pattern.

Final-stage values (`Approved` / `Rejected`, plus a distinct no-approval value only if the user asks for one) and the status field `Overall_Approval_Status__c` are placeholders for the user's Pre-Flight answer (row 6).

Replace the field, queue and flow names with the target org's. Confirm the field exists (`TODO_VERIFY_IN_ORG`).

## Deploy order
1. `Quote.RLM_Approval_Level__c` field (if new) and a permission set granting field access
2. Queues `Manager_Queue`, `Director_Queue`, `VP_Queue` (supported object: Quote)
3. Data subflow (AutoLaunchedFlow)
4. Status subflow (AutoLaunchedFlow)
5. Submit starter (Apex or record-triggered) — starts the process; generic guards only (the process itself handles the nothing-required case)
6. ApprovalWorkflow flow (deploy last)

Deploy queues, then the starter Apex (no tests yet), then the flows; run the Apex tests after the flows exist. A tested starter launches the ApprovalWorkflow and the flow needs the queues, so a single combined deploy with tests fails.

## Queue metadata (repeat per queue)
File name `Manager_Queue.queue-meta.xml` sets the developer name. `<name>` is the label, so it uses spaces.
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Queue xmlns="http://soap.sforce.com/2006/04/metadata">
    <doesSendEmailToMembers>false</doesSendEmailToMembers>
    <name>Manager Queue</name>
    <queueSobject>
        <sobjectType>Quote</sobjectType>
    </queueSobject>
</Queue>
```

## Permission set (field access)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<PermissionSet xmlns="http://soap.sforce.com/2006/04/metadata">
    <fieldPermissions>
        <editable>true</editable>
        <field>Quote.RLM_Approval_Level__c</field>
        <readable>true</readable>
    </fieldPermissions>
    <hasActivationRequired>false</hasActivationRequired>
    <label>Approval Level Access</label>
</PermissionSet>
```

## Data subflow (Stage 1 data retrieval)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Flow xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>ORG_API_VERSION</apiVersion>
    <description>Stage 1 data retrieval: returns Quote RLM_Approval_Level__c</description>
    <environments>Default</environments>
    <interviewLabel>TAS Quote Approval Data {!$Flow.CurrentDateTime}</interviewLabel>
    <label>TAS Quote Approval Data</label>
    <processMetadataValues>
        <name>BuilderType</name>
        <value><stringValue>LightningFlowBuilder</stringValue></value>
    </processMetadataValues>
    <processType>AutoLaunchedFlow</processType>
    <recordLookups>
        <name>Get_Quote</name>
        <label>Get Quote</label>
        <locationX>176</locationX>
        <locationY>158</locationY>
        <filterLogic>and</filterLogic>
        <filters>
            <field>Id</field>
            <operator>EqualTo</operator>
            <value><elementReference>RecordId</elementReference></value>
        </filters>
        <getFirstRecordOnly>true</getFirstRecordOnly>
        <object>Quote</object>
        <outputAssignments>
            <assignToReference>ApprovalLevel</assignToReference>
            <field>RLM_Approval_Level__c</field>
        </outputAssignments>
    </recordLookups>
    <start>
        <locationX>50</locationX>
        <locationY>0</locationY>
        <connector><targetReference>Get_Quote</targetReference></connector>
    </start>
    <status>Active</status>
    <variables>
        <name>ApprovalLevel</name>
        <dataType>Number</dataType>
        <isCollection>false</isCollection>
        <isInput>false</isInput>
        <isOutput>true</isOutput>
        <scale>0</scale>
    </variables>
    <variables>
        <name>RecordId</name>
        <dataType>String</dataType>
        <isCollection>false</isCollection>
        <isInput>true</isInput>
        <isOutput>false</isOutput>
    </variables>
</Flow>
```

## Status subflow (Stage 3 outcome write)
Autolaunched flow `TAS_Set_Quote_Status`, inputs `RecordId` (String) and `NewStatus` (String); output `FaultMessage` (String). One Update Records on `Quote` where `Id = RecordId`, setting `Overall_Approval_Status__c = NewStatus`. The Update Records element has a `<faultConnector>` (supported here, not on stage steps) to an Assignment that stores `{!$Flow.FaultMessage}`; extend it with email or a platform event per the Fault Handling Standard. Both outcome stages call this same subflow, passing `Approved` or `Rejected`. Complete XML: `templates/helper-flow-templates.md` (status subflow). Its inputs are `RecordId` and `NewStatus`.

## ApprovalWorkflow flow
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Flow xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <apiVersion>ORG_API_VERSION</apiVersion>
    <decisions>
        <name>Approval_Outcome</name>
        <label>Approval Outcome</label>
        <locationX>0</locationX>
        <locationY>0</locationY>
        <defaultConnector><targetReference>Approved_Outcome</targetReference></defaultConnector>
        <defaultConnectorLabel>Approved</defaultConnectorLabel>
        <rules>
            <name>Is_Rejected</name>
            <conditionLogic>and</conditionLogic>
            <conditions>
                <leftValueReference>IsAnyRejected</leftValueReference>
                <operator>EqualTo</operator>
                <rightValue><booleanValue>true</booleanValue></rightValue>
            </conditions>
            <connector><targetReference>Rejected_Outcome</targetReference></connector>
            <label>Rejected</label>
        </rules>
    </decisions>
    <description>Serial tiered Quote approval: Manager, Director, VP queues by RLM_Approval_Level__c, then a Decision after the approvals stage routes to a Quote Approved or Quote Rejected stage. Smart Approval enabled. No decision element before the approval stage (it blocks Smart Approval).</description>
    <environments>Default</environments>
    <formulas>
        <name>ApprovalLevelSafe</name>
        <dataType>Number</dataType>
        <expression>IF(ISBLANK({!QueryApprovalData.Outputs.ApprovalLevel}), 0, {!QueryApprovalData.Outputs.ApprovalLevel})</expression>
        <scale>0</scale>
    </formulas>
    <formulas>
        <name>IsAnyRejected</name>
        <dataType>Boolean</dataType>
        <expression>OR({!Manager_Approval.Outputs.approvalDecision} = &quot;Reject&quot;, {!Director_Approval.Outputs.approvalDecision} = &quot;Reject&quot;, {!VP_Approval.Outputs.approvalDecision} = &quot;Reject&quot;)</expression>
    </formulas>
    <formulas>
        <name>IsNothingRequired</name>
        <dataType>Boolean</dataType>
        <expression>{!ApprovalLevelSafe} &lt; 1</expression>
    </formulas>
    <formulas>
        <name>isLevel2Required</name>
        <dataType>Boolean</dataType>
        <expression>AND({!ApprovalLevelSafe} &gt;= 2, {!Manager_Approval.Outputs.approvalDecision} = &quot;Approve&quot;)</expression>
    </formulas>
    <formulas>
        <name>isLevel3Required</name>
        <dataType>Boolean</dataType>
        <expression>AND({!ApprovalLevelSafe} &gt;= 3, {!Director_Approval.Outputs.approvalDecision} = &quot;Approve&quot;)</expression>
    </formulas>
    <formulas>
        <name>IsApprovalsStageComplete</name>
        <dataType>Boolean</dataType>
        <expression>OR(
  {!ApprovalLevelSafe} &lt; 1,
  AND(
    NOT(ISBLANK({!Manager_Approval.Outputs.approvalDecision})),
    OR(NOT({!isLevel2Required}), NOT(ISBLANK({!Director_Approval.Outputs.approvalDecision}))),
    OR(NOT({!isLevel3Required}), NOT(ISBLANK({!VP_Approval.Outputs.approvalDecision})))
  )
)</expression>
    </formulas>
    <interviewLabel>TAS Quote Approval {!$Flow.CurrentDateTime}</interviewLabel>
    <label>TAS Quote Approval</label>
    <orchestratedStages>
        <name>Gather_Quote_Approval_Data</name>
        <label>Gather Quote Approval Data</label>
        <locationX>0</locationX>
        <locationY>0</locationY>
        <connector><targetReference>Quote_Approvals</targetReference></connector>
        <exitConditionLogic>and</exitConditionLogic>
        <stageSteps>
            <name>QueryApprovalData</name>
            <actionName>TAS_Quote_Approval_Data</actionName>
            <actionType>stepBackground</actionType>
            <canAssigneeEdit>false</canAssigneeEdit>
            <entryConditionLogic>and</entryConditionLogic>
            <exitConditionLogic>and</exitConditionLogic>
            <inputParameters>
                <name>RecordId</name>
                <value><elementReference>recordId</elementReference></value>
            </inputParameters>
            <label>QueryApprovalData</label>
            <outputConfigParams>
                <name>ApprovalLevel</name>
                <value xsi:nil="true"/>
            </outputConfigParams>
            <requiresAsyncProcessing>false</requiresAsyncProcessing>
            <runAsUser>false</runAsUser>
            <shouldLock>false</shouldLock>
            <stepSubtype>BackgroundStep</stepSubtype>
        </stageSteps>
    </orchestratedStages>
    <orchestratedStages>
        <name>Quote_Approvals</name>
        <label>Quote Approvals</label>
        <locationX>0</locationX>
        <locationY>0</locationY>
        <connector><targetReference>Approval_Outcome</targetReference></connector>
        <exitConditionLogic>and</exitConditionLogic>
        <exitConditions>
            <conditionType>ExitCondition</conditionType>
            <leftValueReference>IsApprovalsStageComplete</leftValueReference>
            <operator>EqualTo</operator>
            <rightValue><booleanValue>true</booleanValue></rightValue>
        </exitConditions>
        <stageSteps>
            <name>Manager_Approval</name>
            <actionName>standard_approvals__EvaluateApproval</actionName>
            <actionType>stepApproval</actionType>
            <assignees>
                <assignee><stringValue>Manager_Queue</stringValue></assignee>
                <assigneeType>Queue</assigneeType>
            </assignees>
            <canAssigneeEdit>false</canAssigneeEdit>
            <entryConditionLogic>and</entryConditionLogic>
            <entryConditions>
                <conditionType>EntryCondition</conditionType>
                <leftValueReference>QueryApprovalData.Outputs.ApprovalLevel</leftValueReference>
                <operator>GreaterThanOrEqualTo</operator>
                <rightValue><numberValue>1.0</numberValue></rightValue>
            </entryConditions>
            <exitConditionLogic>and</exitConditionLogic>
            <inputParameters>
                <name>ActionInput__RecordId</name>
                <value><elementReference>recordId</elementReference></value>
            </inputParameters>
            <inputParameters>
                <name>ActionInput__ApprovalChainName</name>
                <value><stringValue>Quote_Tiered_Approval</stringValue></value>
            </inputParameters>
            <inputParameters>
                <name>ActionInput__CanUseSmartApproval</name>
                <value><stringValue>true</stringValue></value>
            </inputParameters>
            <label>Manager Approval</label>
            <outputConfigParams>
                <name>approvalDecision</name>
                <value xsi:nil="true"/>
            </outputConfigParams>
            <requiresAsyncProcessing>false</requiresAsyncProcessing>
            <runAsUser>false</runAsUser>
            <shouldLock>false</shouldLock>
            <stepSubtype>ApprovalStep</stepSubtype>
        </stageSteps>
        <stageSteps>
            <name>Director_Approval</name>
            <actionName>standard_approvals__EvaluateApproval</actionName>
            <actionType>stepApproval</actionType>
            <assignees>
                <assignee><stringValue>Director_Queue</stringValue></assignee>
                <assigneeType>Queue</assigneeType>
            </assignees>
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
                <leftValueReference>Manager_Approval.Outputs.approvalDecision</leftValueReference>
                <operator>EqualTo</operator>
                <rightValue><stringValue>Approve</stringValue></rightValue>
            </entryConditions>
            <exitConditionLogic>and</exitConditionLogic>
            <inputParameters>
                <name>ActionInput__RecordId</name>
                <value><elementReference>recordId</elementReference></value>
            </inputParameters>
            <inputParameters>
                <name>ActionInput__ApprovalChainName</name>
                <value><stringValue>Quote_Tiered_Approval</stringValue></value>
            </inputParameters>
            <inputParameters>
                <name>ActionInput__CanUseSmartApproval</name>
                <value><stringValue>true</stringValue></value>
            </inputParameters>
            <label>Director Approval</label>
            <outputConfigParams>
                <name>approvalDecision</name>
                <value xsi:nil="true"/>
            </outputConfigParams>
            <requiresAsyncProcessing>false</requiresAsyncProcessing>
            <runAsUser>false</runAsUser>
            <shouldLock>false</shouldLock>
            <stepSubtype>ApprovalStep</stepSubtype>
        </stageSteps>
        <stageSteps>
            <name>VP_Approval</name>
            <actionName>standard_approvals__EvaluateApproval</actionName>
            <actionType>stepApproval</actionType>
            <assignees>
                <assignee><stringValue>VP_Queue</stringValue></assignee>
                <assigneeType>Queue</assigneeType>
            </assignees>
            <canAssigneeEdit>false</canAssigneeEdit>
            <entryConditionLogic>and</entryConditionLogic>
            <entryConditions>
                <conditionType>EntryCondition</conditionType>
                <leftValueReference>QueryApprovalData.Outputs.ApprovalLevel</leftValueReference>
                <operator>GreaterThanOrEqualTo</operator>
                <rightValue><numberValue>3.0</numberValue></rightValue>
            </entryConditions>
            <entryConditions>
                <conditionType>EntryCondition</conditionType>
                <leftValueReference>Director_Approval.Outputs.approvalDecision</leftValueReference>
                <operator>EqualTo</operator>
                <rightValue><stringValue>Approve</stringValue></rightValue>
            </entryConditions>
            <exitConditionLogic>and</exitConditionLogic>
            <inputParameters>
                <name>ActionInput__RecordId</name>
                <value><elementReference>recordId</elementReference></value>
            </inputParameters>
            <inputParameters>
                <name>ActionInput__ApprovalChainName</name>
                <value><stringValue>Quote_Tiered_Approval</stringValue></value>
            </inputParameters>
            <inputParameters>
                <name>ActionInput__CanUseSmartApproval</name>
                <value><stringValue>true</stringValue></value>
            </inputParameters>
            <label>VP Approval</label>
            <outputConfigParams>
                <name>approvalDecision</name>
                <value xsi:nil="true"/>
            </outputConfigParams>
            <requiresAsyncProcessing>false</requiresAsyncProcessing>
            <runAsUser>false</runAsUser>
            <shouldLock>false</shouldLock>
            <stepSubtype>ApprovalStep</stepSubtype>
        </stageSteps>
    </orchestratedStages>
    <orchestratedStages>
        <name>Approved_Outcome</name>
        <label>Quote Approved</label>
        <locationX>0</locationX>
        <locationY>0</locationY>
        <exitConditionLogic>and</exitConditionLogic>
        <stageSteps>
            <name>SetApproved</name>
            <actionName>TAS_Set_Quote_Status</actionName>
            <actionType>stepBackground</actionType>
            <canAssigneeEdit>false</canAssigneeEdit>
            <entryConditionLogic>and</entryConditionLogic>
            <exitConditionLogic>and</exitConditionLogic>
            <inputParameters><name>RecordId</name><value><elementReference>recordId</elementReference></value></inputParameters>
            <inputParameters><name>NewStatus</name><value><stringValue>Approved</stringValue></value></inputParameters>
            <label>Set Status Approved</label>
            <requiresAsyncProcessing>false</requiresAsyncProcessing>
            <runAsUser>false</runAsUser>
            <shouldLock>false</shouldLock>
            <stepSubtype>BackgroundStep</stepSubtype>
        </stageSteps>
    </orchestratedStages>
    <orchestratedStages>
        <name>Rejected_Outcome</name>
        <label>Quote Rejected</label>
        <locationX>0</locationX>
        <locationY>0</locationY>
        <exitConditionLogic>and</exitConditionLogic>
        <stageSteps>
            <name>SetRejected</name>
            <actionName>TAS_Set_Quote_Status</actionName>
            <actionType>stepBackground</actionType>
            <canAssigneeEdit>false</canAssigneeEdit>
            <entryConditionLogic>and</entryConditionLogic>
            <exitConditionLogic>and</exitConditionLogic>
            <inputParameters><name>RecordId</name><value><elementReference>recordId</elementReference></value></inputParameters>
            <inputParameters><name>NewStatus</name><value><stringValue>Rejected</stringValue></value></inputParameters>
            <label>Set Status Rejected</label>
            <requiresAsyncProcessing>false</requiresAsyncProcessing>
            <runAsUser>false</runAsUser>
            <shouldLock>false</shouldLock>
            <stepSubtype>BackgroundStep</stepSubtype>
        </stageSteps>
    </orchestratedStages>
    <processMetadataValues>
        <name>CanvasMode</name>
        <value><stringValue>AUTO_LAYOUT_CANVAS</stringValue></value>
    </processMetadataValues>
    <processType>ApprovalWorkflow</processType>
    <runInMode>SystemModeWithoutSharing</runInMode>
    <start>
        <locationX>0</locationX>
        <locationY>0</locationY>
        <connector><targetReference>Gather_Quote_Approval_Data</targetReference></connector>
    </start>
    <status>Active</status>
    <variables><name>firstApprover</name><dataType>String</dataType><isCollection>false</isCollection><isInput>true</isInput><isOutput>false</isOutput></variables>
    <variables><name>recordId</name><dataType>String</dataType><isCollection>false</isCollection><isInput>true</isInput><isOutput>false</isOutput></variables>
    <variables><name>submissionComments</name><dataType>String</dataType><isCollection>false</isCollection><isInput>true</isInput><isOutput>false</isOutput></variables>
    <variables><name>submitter</name><dataType>String</dataType><isCollection>false</isCollection><isInput>true</isInput><isOutput>false</isOutput></variables>
</Flow>
```

## Expected deploy messages (informational, not failures)
- Automated Process User has no valid email: step emails cannot send until fixed in Process Automation Settings.
- Orchestrations with User/Group/Queue assignees cannot be packaged.
- Queues are not associated with Orchestration Work Item: no Omni-Channel notification, email only.
