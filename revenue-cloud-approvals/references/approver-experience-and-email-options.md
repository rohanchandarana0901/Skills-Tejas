# Approver Screen and Approver Email Options

> **Examples in this file are illustrative.** Object, field and flow names are placeholders; substitute the target org's values and mark anything unconfirmed `TODO_VERIFY_IN_ORG`.

Pre-Flight rows 14 (approver screen) and 15 (approver emails) point here. Both are optional; the defaults need no extra component.

## Verified against Salesforce Help (flow approval processes)

- An approval step runs an active screen flow. The flow must contain a text output variable named `approvalDecision`; valid values are `Approve` or `Reject`. A missing or invalid value makes the approval process fail.
- Approvers can approve or reject a work item without running the screen flow. Put only what the decision needs on the screen; do any other action (update records, notify) in a background step after the approval step.
- The step's approver type is `User`, `Group` (public group), `Queue`, or `Resource` (a variable holding a username, a group API name or a queue API name).
- A custom email is set per approval step: **Customize notification email**, with a subject (a text template resource or a plain string) and a body (a text template resource). Each step can use a different set of templates.
- The sender cannot be customized. Emails come from the Automated Process User email address in Process Automation Settings, then an organization-wide default no-reply address, then any verified organization-wide address, then the running user's address. If the run is in system context with no user, no email is sent.
- A reassigned work item sends the default notification to the new approver even when the step has a custom email.
- All approver emails also need the org settings and step option listed in `references/email-templates-advanced-approvals.md`.

## Option: custom approver screen flow (row 14)

When to offer: the request mentions what the approver sees (a record summary, extra fields, a custom decision form).

Build a screen flow (`processType: Flow`) with:
- input `recordId` (String), used by a Get Records element to load the record;
- a screen that displays the record details the user names, a required radio field with the choices `Approve` and `Reject`, and an optional comments text area;
- output variable `approvalDecision` (String) whose value is the radio field;
- output variable `approvalComments` (String) whose value is the comments field. This second output was seen in a deployed project flow; it is not required by the documentation, so confirm it in the org before relying on it (`TODO_VERIFY_IN_ORG`).

```xml
<choices>
    <name>ApproveChoice</name>
    <choiceText>Approve</choiceText>
    <dataType>String</dataType>
    <value><stringValue>Approve</stringValue></value>
</choices>
<choices>
    <name>RejectChoice</name>
    <choiceText>Reject</choiceText>
    <dataType>String</dataType>
    <value><stringValue>Reject</stringValue></value>
</choices>
<!-- screen fields -->
<fields>
    <name>DecisionRadio</name>
    <choiceReferences>ApproveChoice</choiceReferences>
    <choiceReferences>RejectChoice</choiceReferences>
    <dataType>String</dataType>
    <fieldText>Approval Decision</fieldText>
    <fieldType>RadioButtons</fieldType>
    <isRequired>true</isRequired>
</fields>
<fields>
    <name>DecisionComments</name>
    <fieldText>Decision Comments</fieldText>
    <fieldType>LargeTextArea</fieldType>
    <isRequired>false</isRequired>
</fields>
<!-- outputs -->
<variables>
    <name>approvalDecision</name>
    <dataType>String</dataType>
    <isCollection>false</isCollection>
    <isInput>false</isInput>
    <isOutput>true</isOutput>
    <value><elementReference>DecisionRadio</elementReference></value>
</variables>
<variables>
    <name>approvalComments</name>
    <dataType>String</dataType>
    <isCollection>false</isCollection>
    <isInput>false</isInput>
    <isOutput>true</isOutput>
    <value><elementReference>DecisionComments</elementReference></value>
</variables>
```

In the ApprovalWorkflow, the step changes only its action and inputs:

```xml
<actionName><ScreenFlowApiName></actionName>
<actionType>stepApproval</actionType>
...
<inputParameters>
    <name>recordId</name>
    <value><elementReference>recordId</elementReference></value>
</inputParameters>
<inputParameters>
    <name>ActionInput__RecordId</name>
    <value><elementReference>recordId</elementReference></value>
</inputParameters>
<!-- keep ActionInput__ApprovalChainName and ActionInput__CanUseSmartApproval as for the standard action -->
<outputConfigParams>
    <name>approvalDecision</name>
    <value xsi:nil="true"/>
</outputConfigParams>
<outputConfigParams>
    <name>approvalComments</name>
    <value xsi:nil="true"/>
</outputConfigParams>
```

`recordId` is valid only because the step calls your own screen flow (Deployment Contract rule 9). Deploy and activate the screen flow before the ApprovalWorkflow. Smart Approval settings were seen on steps that call a custom screen flow in a project flow; retest resubmission after building one.

Cost of the option: one more component to deploy, test and maintain, and approvers who decide without opening the screen never see it.

## Option: custom approver email (row 15)

When to offer: the request mentions email wording, subject, body or branding.

1. Tell the user the three limits first: sender cannot change, a reassigned work item sends the default email, and the org email settings must be on.
2. In the ApprovalWorkflow, create two text template resources per step (or one pair shared by steps): subject and body. Use merge references the process can resolve (for example the record id from the gather step), and keep the wording the user supplied.
3. On each chosen step set the custom email inputs. In the project flows they appear as step inputs `ActionInput__CustomEmailSubject` and `ActionInput__CustomEmailBody`, left empty there. The exact value format for a text template reference is not shown by an empty input, so save one step with a custom email in Flow Builder and read it before generating (`TODO_VERIFY_IN_ORG`).
4. Confirm the org email settings and test with a real work item (a queue with no members sends no one an email; add a test user only if the user asks).

## Seen in a project flow, meaning not confirmed

These appeared in a deployed project approval flow. Do not generate them unless the user asks, and read the meaning from a step saved in Flow Builder first (`TODO_VERIFY_IN_ORG`):
- step input `ActionInput__CanUseRuleBasedAutoApprovals`
- step input `ActionInput__ApprovalOverrideDecision`
- process-level value `SendNoApproverEmails` (value `false` in the project flow)
