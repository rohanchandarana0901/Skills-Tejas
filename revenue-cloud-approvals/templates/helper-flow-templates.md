# Helper Flow Templates (gather subflow, status subflow)

Complete autolaunched flows used by the ApprovalWorkflow's background steps. Illustrative: replace `<Object>`, `<Domain>`, field names and `ORG_API_VERSION` with the user's values; confirm every field exists in the org first (Deployment Contract rule 6). Both flows were deployed and ran inside a tested approval process.

Fault handling lives here, not on the stage steps (Fault Handling Standard).

## Gather subflow: null-safe level plus two flags (`<Domain>_<Object>_Approval_Data.flow-meta.xml`)

Inputs: `RecordId`. Outputs: `ApprovalLevel` (Number, scale 0, `0` when blank), `IsLegalRequired`, `IsFinanceRequired` (Boolean). For a different set of flags or no level, add or remove the matching output variable, lookup assignment and `<outputConfigParams>` entry in the ApprovalWorkflow step.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Flow xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>ORG_API_VERSION</apiVersion>
    <assignments>
        <name>Set_Safe_Level</name>
        <label>Set Safe Level</label>
        <locationX>0</locationX>
        <locationY>0</locationY>
        <assignmentItems>
            <assignToReference>ApprovalLevel</assignToReference>
            <operator>Assign</operator>
            <value><elementReference>SafeLevel</elementReference></value>
        </assignmentItems>
    </assignments>
    <environments>Default</environments>
    <formulas>
        <name>SafeLevel</name>
        <dataType>Number</dataType>
        <expression>IF(ISBLANK({!rawLevel}), 0, {!rawLevel})</expression>
        <scale>0</scale>
    </formulas>
    <interviewLabel><Domain> <Object> Approval Data {!$Flow.CurrentDateTime}</interviewLabel>
    <label><Domain> <Object> Approval Data</label>
    <processMetadataValues>
        <name>BuilderType</name>
        <value><stringValue>LightningFlowBuilder</stringValue></value>
    </processMetadataValues>
    <processMetadataValues>
        <name>CanvasMode</name>
        <value><stringValue>AUTO_LAYOUT_CANVAS</stringValue></value>
    </processMetadataValues>
    <processType>AutoLaunchedFlow</processType>
    <recordLookups>
        <name>Get_Record</name>
        <label>Get Record</label>
        <locationX>0</locationX>
        <locationY>0</locationY>
        <connector><targetReference>Set_Safe_Level</targetReference></connector>
        <filterLogic>and</filterLogic>
        <filters>
            <field>Id</field>
            <operator>EqualTo</operator>
            <value><elementReference>RecordId</elementReference></value>
        </filters>
        <getFirstRecordOnly>true</getFirstRecordOnly>
        <object><Object></object>
        <outputAssignments><assignToReference>rawLevel</assignToReference><field><LevelField></field></outputAssignments>
        <outputAssignments><assignToReference>IsLegalRequired</assignToReference><field><LegalCheckbox></field></outputAssignments>
        <outputAssignments><assignToReference>IsFinanceRequired</assignToReference><field><FinanceCheckbox></field></outputAssignments>
    </recordLookups>
    <start>
        <locationX>0</locationX>
        <locationY>0</locationY>
        <connector><targetReference>Get_Record</targetReference></connector>
    </start>
    <status>Active</status>
    <variables>
        <name>ApprovalLevel</name>
        <dataType>Number</dataType>
        <isCollection>false</isCollection>
        <isInput>false</isInput>
        <isOutput>true</isOutput>
        <scale>0</scale>
        <value><numberValue>0.0</numberValue></value>
    </variables>
    <variables>
        <name>IsFinanceRequired</name>
        <dataType>Boolean</dataType>
        <isCollection>false</isCollection>
        <isInput>false</isInput>
        <isOutput>true</isOutput>
        <value><booleanValue>false</booleanValue></value>
    </variables>
    <variables>
        <name>IsLegalRequired</name>
        <dataType>Boolean</dataType>
        <isCollection>false</isCollection>
        <isInput>false</isInput>
        <isOutput>true</isOutput>
        <value><booleanValue>false</booleanValue></value>
    </variables>
    <variables>
        <name>RecordId</name>
        <dataType>String</dataType>
        <isCollection>false</isCollection>
        <isInput>true</isInput>
        <isOutput>false</isOutput>
    </variables>
    <variables>
        <name>rawLevel</name>
        <dataType>Number</dataType>
        <isCollection>false</isCollection>
        <isInput>false</isInput>
        <isOutput>false</isOutput>
        <scale>0</scale>
    </variables>
</Flow>
```

## Status subflow (`<Domain>_Set_<Object>_Status.flow-meta.xml`)

Used by every status write the user chose in Pre-Flight row 6 (at submit, approved, rejected, nothing required). Inputs: `RecordId`, `NewStatus`. Output: `FaultMessage`. Replace `Status` with the field the user chose. Each background step in the ApprovalWorkflow passes the value the user gave for that event; never hard-code a value in the subflow.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Flow xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>ORG_API_VERSION</apiVersion>
    <assignments>
        <name>Store_Fault</name>
        <label>Store Fault</label>
        <locationX>0</locationX>
        <locationY>0</locationY>
        <assignmentItems>
            <assignToReference>FaultMessage</assignToReference>
            <operator>Assign</operator>
            <value><elementReference>$Flow.FaultMessage</elementReference></value>
        </assignmentItems>
    </assignments>
    <environments>Default</environments>
    <interviewLabel><Domain> Set <Object> Status {!$Flow.CurrentDateTime}</interviewLabel>
    <label><Domain> Set <Object> Status</label>
    <processMetadataValues>
        <name>BuilderType</name>
        <value><stringValue>LightningFlowBuilder</stringValue></value>
    </processMetadataValues>
    <processMetadataValues>
        <name>CanvasMode</name>
        <value><stringValue>AUTO_LAYOUT_CANVAS</stringValue></value>
    </processMetadataValues>
    <processType>AutoLaunchedFlow</processType>
    <recordUpdates>
        <name>Update_Status</name>
        <label>Update Status</label>
        <locationX>0</locationX>
        <locationY>0</locationY>
        <faultConnector><targetReference>Store_Fault</targetReference></faultConnector>
        <filterLogic>and</filterLogic>
        <filters>
            <field>Id</field>
            <operator>EqualTo</operator>
            <value><elementReference>RecordId</elementReference></value>
        </filters>
        <inputAssignments>
            <field>Status</field>
            <value><elementReference>NewStatus</elementReference></value>
        </inputAssignments>
        <object><Object></object>
    </recordUpdates>
    <start>
        <locationX>0</locationX>
        <locationY>0</locationY>
        <connector><targetReference>Update_Status</targetReference></connector>
    </start>
    <status>Active</status>
    <variables>
        <name>FaultMessage</name>
        <dataType>String</dataType>
        <isCollection>false</isCollection>
        <isInput>false</isInput>
        <isOutput>true</isOutput>
    </variables>
    <variables>
        <name>NewStatus</name>
        <dataType>String</dataType>
        <isCollection>false</isCollection>
        <isInput>true</isInput>
        <isOutput>false</isOutput>
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

Background step calling it (inside an `orchestratedStages` element):

```xml
<stageSteps>
    <name>SetApproved</name>
    <actionName><Domain>_Set_<Object>_Status</actionName>
    <actionType>stepBackground</actionType>
    <canAssigneeEdit>false</canAssigneeEdit>
    <entryConditionLogic>and</entryConditionLogic>
    <exitConditionLogic>and</exitConditionLogic>
    <inputParameters>
        <name>RecordId</name>
        <value><elementReference>recordId</elementReference></value>
    </inputParameters>
    <inputParameters>
        <name>NewStatus</name>
        <value><stringValue>THE_VALUE_THE_USER_CHOSE</stringValue></value>
    </inputParameters>
    <label>Set Status Approved</label>
    <requiresAsyncProcessing>false</requiresAsyncProcessing>
    <runAsUser>false</runAsUser>
    <shouldLock>false</shouldLock>
    <stepSubtype>BackgroundStep</stepSubtype>
</stageSteps>
```
