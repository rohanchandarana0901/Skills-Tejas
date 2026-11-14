# Submit Chain Templates (button, screen flow, queue, public group)

Illustrative. Replace `<Object>`, `<Domain>` and `<ApprovalFlowApiName>`. The chain is: quick action -> screen flow -> Apex starter (`ApprovalStarter.cls`) -> ApprovalWorkflow. Names follow Pre-Flight row 13.

Deploy order: queues, starter Apex (`NoTestRun`), helper flows, ApprovalWorkflow, then the screen flow and quick action. Run the Apex test last (see SKILL.md, Deployment Contract rule 10). A quick action is not visible until placed on a page layout or Lightning record page.

## Quick action (`<Object>.Submit_<Object>_<Domain>_Approval.quickAction-meta.xml`)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<QuickAction xmlns="http://soap.sforce.com/2006/04/metadata">
    <flowDefinition><Object>_<Domain>_Submit</flowDefinition>
    <label>Submit for <Domain> Approval</label>
    <optionsCreateFeedItem>false</optionsCreateFeedItem>
    <type>Flow</type>
</QuickAction>
```

## Screen flow (`<Object>_<Domain>_Submit.flow-meta.xml`), without a comments screen
A quick action of type Flow needs a screen flow. This one calls the starter and shows the result message.
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Flow xmlns="http://soap.sforce.com/2006/04/metadata">
    <actionCalls>
        <name>Submit_Approval</name>
        <label>Submit Approval</label>
        <locationX>176</locationX>
        <locationY>158</locationY>
        <actionName><Object><Domain>ApprovalStarter</actionName>
        <actionType>apex</actionType>
        <connector><targetReference>Result</targetReference></connector>
        <flowTransactionModel>CurrentTransaction</flowTransactionModel>
        <inputParameters>
            <name>recordId</name>
            <value><elementReference>recordId</elementReference></value>
        </inputParameters>
        <nameSegment><Object><Domain>ApprovalStarter</nameSegment>
        <outputParameters>
            <assignToReference>resultMessage</assignToReference>
            <name>message</name>
        </outputParameters>
    </actionCalls>
    <apiVersion>ORG_API_VERSION</apiVersion>
    <environments>Default</environments>
    <interviewLabel><Object> <Domain> Submit {!$Flow.CurrentDateTime}</interviewLabel>
    <label><Object> <Domain> Submit</label>
    <processMetadataValues>
        <name>BuilderType</name>
        <value><stringValue>LightningFlowBuilder</stringValue></value>
    </processMetadataValues>
    <processType>Flow</processType>
    <screens>
        <name>Result</name>
        <label>Result</label>
        <locationX>176</locationX>
        <locationY>278</locationY>
        <allowBack>false</allowBack>
        <allowFinish>true</allowFinish>
        <allowPause>false</allowPause>
        <fields>
            <name>ResultText</name>
            <fieldText>&lt;p&gt;{!resultMessage}&lt;/p&gt;</fieldText>
            <fieldType>DisplayText</fieldType>
        </fields>
        <showFooter>true</showFooter>
        <showHeader>true</showHeader>
    </screens>
    <start>
        <locationX>50</locationX>
        <locationY>0</locationY>
        <connector><targetReference>Submit_Approval</targetReference></connector>
    </start>
    <status>Active</status>
    <variables>
        <name>recordId</name>
        <dataType>String</dataType>
        <isCollection>false</isCollection>
        <isInput>true</isInput>
        <isOutput>false</isOutput>
    </variables>
    <variables>
        <name>resultMessage</name>
        <dataType>String</dataType>
        <isCollection>false</isCollection>
        <isInput>false</isInput>
        <isOutput>false</isOutput>
    </variables>
</Flow>
```

### Optional: submitter comments screen
Offer only per Pre-Flight row 16 (manual start, submitter may add comments for approvers). Add a screen before `Submit_Approval` with one `LargeTextArea` field named `Comments` (not required), a `nextOrFinishButtonLabel` of `Submit`, and pass `{!Comments}` as the starter's `comments` input (it becomes `submissionComments` on the process). Make the screen the flow's `start` connector target.

## Queue (`<Prefix>_<Role>_Queue.queue-meta.xml`)
The developer name comes from the file name. `<name>` is the label shown to users, so write it with spaces.
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Queue xmlns="http://soap.sforce.com/2006/04/metadata">
    <doesSendEmailToMembers>false</doesSendEmailToMembers>
    <name><Prefix> <Role> Queue</name>
    <queueSobject>
        <sobjectType><Object></sobjectType>
    </queueSobject>
</Queue>
```
Reference the queue in a step by its developer name (the file name without the extension), with `assigneeType` `Queue`.

## Public group (`<Prefix>_<Role>_Group.group-meta.xml`)
Use when the user chose public groups as approvers (Pre-Flight row 4). The developer name comes from the file name; `<name>` is the label shown to users, so write it with spaces. Write only `<name>`: the `Group` metadata type rejects `doesIncludeBossSubordinates` here (deploy error `Element ... doesIncludeBossSubordinates invalid at this location in type Group`).
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Group xmlns="http://soap.sforce.com/2006/04/metadata">
    <name><Prefix> <Role> Group</name>
</Group>
```
Deploy: `sf project deploy start --target-org <alias> --metadata Group:<Prefix>_<Role>_Group --test-level NoTestRun`. Groups must exist before the ApprovalWorkflow deploys (error otherwise: `The assigned group "<Prefix>_<Role>_Group" in the assignee field doesn't exist`). In the step, use `assigneeType` `Group` and the developer name:
```xml
<assignees>
    <assignee><stringValue><Prefix>_<Role>_Group</stringValue></assignee>
    <assigneeType>Group</assigneeType>
</assignees>
```
A new group has no members, so UI users see no tasks until members are added; API test approvals still work. Public groups are not tied to an object, so no `queueSobject` is needed.
