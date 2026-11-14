# Approval Reminder Pattern

Use this reference when designing reminder notifications for pending Revenue Cloud / RLM Flow-based approvals.

## Core Pattern

Use a Record-Triggered Flow on the approval work item object with one or more Scheduled Paths. Each scheduled path waits for a user-confirmed reminder interval, verifies the item is still pending, then sends the user-confirmed reminder email/template to the current owner/assignee.

This is a notification helper. It must not replace the main Advanced Approval orchestration.

## Mandatory Reminder Questions

Before designing or generating reminder setup steps, ask:

1. How many approval reminders are required?
2. For each reminder, when should it be sent?
   - Example: 1 day after assignment, 3 business days after assignment, 24 hours before due date.
3. For each reminder, what email content or email template should be used?
   - Ask whether the user wants a plain Flow text template, an existing Salesforce Email Template, or a new email template.
4. Who should receive each reminder?
   - Current work item owner/assignee, original approver, submitter, manager, queue email, or escalation recipient.

Do not hardcode:

- number of reminders
- number of days or hours
- email subject
- email body
- email template developer name
- recipient strategy

If the user asks for multiple reminders, collect timing and email/template details separately for each reminder.

## Assumptions to Verify

Mark these as `TODO_VERIFY_IN_ORG` unless confirmed by target-org metadata:

- Pending status value: `Assigned` (standard).
- Current assignee field: `AssignedToId` (user, group, or queue).
- Whether email recipients can be users, queues, or both.
- Whether queue-owned work items need special routing to members or a queue email address.
- Whether the org allows the standard Flow `Send Email` action for the intended recipient type.
- Whether business-day timing is required; Scheduled Paths use calendar-based offsets unless a custom business-hours pattern is implemented.

## Recommended Flow Setup

Create a Record-Triggered Flow:

```text
Object: ApprovalWorkItem
Trigger: Created or Updated
Entry condition: Status Equals Assigned
Updated records: Only when updated to meet condition requirements
Optimize for: Actions and Related Records
```

**Object name is always `ApprovalWorkItem` for Revenue Cloud / RLM Flow-based Advanced Approvals. Do not substitute any other object name.**

## Validated Flow XML Skeleton

The following skeleton is validated. Set `ORG_API_VERSION` to the org's current API version and substitute `REMINDER_LABEL`, `OFFSET_NUMBER`, `OFFSET_UNIT`, `EMAIL_SUBJECT_FORMULA`, `EMAIL_BODY_FORMULA` with user-confirmed values.

**Critical enum values — do not change:**
- `timeSource`: `RecordTriggerEvent` (not `CreatedDate`, not `RecordField`)
- `pathType`: omit entirely
- Flow termination: omit `<defaultConnector>` on branches that end — do NOT reference `End`
- Email recipient: use Get Records to fetch `User` by `OwnerId`, then reference `Get_Owner_User.Email`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Flow xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>ORG_API_VERSION</apiVersion>
    <description>Record-triggered flow on ApprovalWorkItem. Sends plain-text reminder email to work item owner at configured interval. Part of Revenue Cloud Quote Approval process.</description>
    <environments>Default</environments>
    <processType>AutoLaunchedFlow</processType>
    <status>Draft</status>
    <label>FLOW_LABEL</label>
    <interviewLabel>FLOW_LABEL {!$Flow.CurrentDateTime}</interviewLabel>

    <!-- Formula: email subject merging work item name -->
    <formulas>
        <name>EmailSubject</name>
        <dataType>String</dataType>
        <expression>EMAIL_SUBJECT_FORMULA</expression>
    </formulas>

    <!-- Formula: email body merging work item name -->
    <formulas>
        <name>EmailBody</name>
        <dataType>String</dataType>
        <expression>EMAIL_BODY_FORMULA</expression>
    </formulas>

    <!-- Get Records: resolve OwnerId to User email -->
    <recordLookups>
        <name>Get_Owner_User</name>
        <label>Get Owner User</label>
        <locationX>176</locationX>
        <locationY>683</locationY>
        <assignNullValuesIfNoRecordsFound>false</assignNullValuesIfNoRecordsFound>
        <connector>
            <targetReference>Send_Reminder_Email</targetReference>
        </connector>
        <filterLogic>and</filterLogic>
        <filters>
            <field>Id</field>
            <operator>EqualTo</operator>
            <value>
                <elementReference>$Record.OwnerId</elementReference>
            </value>
        </filters>
        <getFirstRecordOnly>true</getFirstRecordOnly>
        <object>User</object>
        <storeOutputAutomatically>true</storeOutputAutomatically>
    </recordLookups>

    <!-- Send Email: plain text, no template -->
    <actionCalls>
        <name>Send_Reminder_Email</name>
        <label>Send Reminder Email</label>
        <locationX>176</locationX>
        <locationY>791</locationY>
        <actionName>emailSimple</actionName>
        <actionType>emailSimple</actionType>
        <flowTransactionModel>CurrentTransaction</flowTransactionModel>
        <inputParameters>
            <name>emailAddresses</name>
            <value>
                <elementReference>Get_Owner_User.Email</elementReference>
            </value>
        </inputParameters>
        <inputParameters>
            <name>emailSubject</name>
            <value>
                <elementReference>EmailSubject</elementReference>
            </value>
        </inputParameters>
        <inputParameters>
            <name>emailBody</name>
            <value>
                <elementReference>EmailBody</elementReference>
            </value>
        </inputParameters>
    </actionCalls>

    <!-- Decision: verify work item still pending before sending -->
    <decisions>
        <name>Is_Still_Pending</name>
        <label>Is Still Pending?</label>
        <locationX>176</locationX>
        <locationY>575</locationY>
        <!-- Default outcome: omit connector — flow terminates implicitly -->
        <defaultConnectorLabel>Default Outcome</defaultConnectorLabel>
        <rules>
            <name>Still_Assigned</name>
            <conditionLogic>and</conditionLogic>
            <conditions>
                <leftValueReference>$Record.Status</leftValueReference>
                <operator>EqualTo</operator>
                <rightValue>
                    <stringValue>Assigned</stringValue>
                </rightValue>
            </conditions>
            <connector>
                <targetReference>Get_Owner_User</targetReference>
            </connector>
            <label>Still Assigned</label>
        </rules>
    </decisions>

    <start>
        <locationX>50</locationX>
        <locationY>0</locationY>
        <doesRequireRecordChangedToMeetCriteria>true</doesRequireRecordChangedToMeetCriteria>
        <filterLogic>and</filterLogic>
        <filters>
            <field>Status</field>
            <operator>EqualTo</operator>
            <value>
                <stringValue>Assigned</stringValue>
            </value>
        </filters>
        <object>ApprovalWorkItem</object>
        <recordTriggerType>CreateAndUpdate</recordTriggerType>
        <scheduledPaths>
            <name>REMINDER_LABEL</name>
            <connector>
                <targetReference>Is_Still_Pending</targetReference>
            </connector>
            <label>REMINDER_LABEL</label>
            <offsetNumber>OFFSET_NUMBER</offsetNumber>
            <offsetUnit>OFFSET_UNIT</offsetUnit>
            <!-- timeSource MUST be RecordTriggerEvent — do not use CreatedDate or RecordField -->
            <timeSource>RecordTriggerEvent</timeSource>
        </scheduledPaths>
        <triggerType>RecordAfterSave</triggerType>
    </start>

</Flow>
```

Use `Actions and Related Records` so Scheduled Paths are available.

## Scheduled Paths

Create one scheduled path for each user-confirmed reminder:

```text
Path Label: <Reminder Label from user>
Time Source: <Confirmed time source, usually ApprovalWorkItem.CreatedDate>
Offset: <Confirmed number and unit>
```

Examples only, not defaults:

```text
Reminder 1: 1 Day After CreatedDate
Reminder 2: 3 Days After CreatedDate
Reminder 3: 5 Days After CreatedDate
```

For recurring reminders until completion, consider a scheduled flow or separate reminder tracking design instead of many hardcoded scheduled paths.

## Pending Check

On each scheduled path, add a Decision before sending email:

```text
Decision: Is Still Pending?
Outcome: Yes, Still Assigned
Condition: $Record.Status Equals Assigned
Default Outcome: End
```

This prevents reminders after the work item has been approved, rejected, reassigned, or canceled.

## Send Email Action

On each pending branch, add the Flow `Send Email` action or template-based email action using the user-confirmed message/template for that reminder.

Configuration must come from user input:

```text
Label: <Reminder-specific action label>
Recipient: <Confirmed recipient strategy>
Subject or Template: <Confirmed subject/template>
Body: <Confirmed body or text template>
```

If `OwnerId` can be a queue, verify recipient behavior. If queue reminders are required, route to queue email or resolve queue members with a separate helper flow.

## Canvas Shape

```text
[Start: ApprovalWorkItem Created/Updated to Assigned]
       |
       +--> Run Immediately --> End
       |
       +--> Scheduled Path: Reminder 1 at confirmed time
       |         |
       |         v
       |  [Decision: Is Still Pending?]
       |         |
       |         v
       |  [Action: Send confirmed Reminder 1 email/template]
       |
       +--> Scheduled Path: Reminder 2 at confirmed time
                 |
                 v
          [Decision: Is Still Pending?]
                 |
                 v
          [Action: Send confirmed Reminder 2 email/template]
```

## Testing

Test at minimum:

1. Each configured reminder sends at its confirmed interval when the work item is still assigned.
2. Work item approved before a reminder time sends no email for that reminder.
3. Work item rejected/canceled before a reminder time sends no email.
4. Work item reassigned before reminder time sends to the expected current recipient or follows the approved queue behavior.
5. Each reminder uses the correct confirmed email/template.
6. Queue-owned work item behavior matches business expectations.

## Deployment and Activation

Deploy inactive first when possible, validate object/field/status references, then activate in the target org.

Activation order:

1. Email templates or text template resources, if created separately.
2. Helper flow for queue/member resolution, if needed.
3. Approval Reminder record-triggered flow.

## Risks and Guardrails

- Do not assume `ApprovalWorkItem`, `Status = Assigned`, or `OwnerId` without org verification.
- Do not assume reminder count, timing, subject, body, template, or recipient strategy.
- Do not send reminders from the immediate path unless the user explicitly wants instant notifications.
- Avoid creating duplicate reminder flows for the same interval and object.
- For high-volume approval orgs, assess scheduled path interview volume and email limits.
- For escalations, design a separate escalation path rather than overloading reminder email logic.
