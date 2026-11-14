# Advanced Approvals Considerations (Official)

Source hub: https://help.salesforce.com/s/articleView?id=ind.approvals_advanced_approvals_considerations.htm&type=5 (verified 2026-06-12)

Official known limitations, system boundaries, and expected behaviors for Advanced Approvals. Nine sections, each with its own child article. Facts below are documented by Salesforce — treat them as authoritative. For design-pattern guidance (workarounds, escalation patterns), see `advanced-approvals-limitations.md`.

Editions: Lightning Experience — Enterprise, Unlimited, Developer where Advanced Approvals is enabled.

## 1. Objects and Record Access

Child: `ind.approvals_objects_considerations.htm`

- Approval requests can be triggered only from supported objects.
- **ApprovalSubmission controls access to the other approval objects** — granting a user access to ApprovalSubmission grants access to its child records (submission details, work items).
- All approval records default to **Private**.
- If the related record's OWD is **Public Read Only**, all users automatically get access to its approval submissions and work items. If **Private**, share temporary access via Apex triggers — see `trigger-based-approval-record-sharing.md`.
- **You cannot manually share ApprovalSubmission records.**
- **ApprovalWorkItem sharing can be tightened:** by default, access to a submission extends to all its work items. Set the `ApprovalWorkItem` org-wide default to **Private** so reviewers see only work items assigned or delegated to them (other-step reviewers are blocked; the submission owner/submitter can view but not review/reassign). Extend read access with criteria-based sharing rules on `ApprovalWorkItem`.
- **Deletion / GDPR:** deleting the parent record automatically cancels in-progress approval submissions and their in-progress child records; the submissions can then be deleted.

## 2. Environment & Setup

Child: `ind.approvals_environment_setup.htm`

- **Sandbox permission discrepancy:** run the **Match Production License** tool in the sandbox (especially after a release), or sandbox user permissions are not upgraded and users lack features available in production.

## 3. Design, Build, and Activation

Child: `ind.approvals_design_build_activation.htm`

- A flow with validation errors cannot be activated; errors appear on the Flow Builder Error tab.
- **CUD via sObject APIs on standard fields of approval objects fails.** Update approval records using the standard invocable actions or alternate flows. Custom fields CAN be updated via the APIs.
- **Apex triggers must avoid create/update/delete on standard approval fields** — those operations fail. Triggers may update custom fields.

## 4. Approval Process Execution

Child: `ind.approvals_approval_process_execution.htm`

- Errored flow state common causes: **multiple steps trying to lock the same record simultaneously**, or **Work Item screen guide rendering issues**. Diagnose via Setup → **Paused and Failed Interviews**, or the error email sent to the admin user.
- **Multiple reviewers conflict:** when two members of a group/queue act on the same work item, the first completion wins; the second user gets "work item is already completed". Normal system operation — no action required.

## 5. User Interface, Component, and List View Behavior

Child: `ind.approvals_create_a_flow_to_update_records.htm`

- **Approval Trace component is predefined and locked** — not customizable. It shows only the record associated with the approval submission, not related records (e.g., quote line item submission does not show parent quote work items). If single-page extended visibility is required, redesign the approval flow.
- The **Assigned Approval Work Items** list view filters cannot be modified.
- **ApprovalWorkItem has no Owner field** — custom list views cannot filter work items by ownership; use the Assigned Approval Work Items list view.
- Sharing settings of default Advanced Approvals list views cannot be modified; default list views cannot be deleted.
- Approval object page layouts cannot be customized before records exist. Viewing a record after creation activates the default layout (App Launcher → approval object → list view → open record → Details tab).

## 6. Emails

Child: `ind.approvals_email_notification_behavior.htm`

- Enabling notifications requires BOTH: **Send Approval Work Item Assignment Emails** + **Send Approval Submission Status Email Notifications** in Advanced Approval settings, AND deselecting **Don't send approver notifications** on the approval step.
- Custom email templates must be marked **Available for Use**.
- Template **entity must match the approval workflow's target object**.
- Only **one email template per combination of approval flow + approval step + notification reason**.
- A template on an approval alert content definition record **overrides** the custom email specified on the approval step.
- A template not associated with a specific step applies to **all steps lacking a unique template**.
- **Email replies:** decision keyword (e.g. Approve) must be on the FIRST line, comment on the SECOND line — otherwise the comment is not captured.
- If the org hits its email limit, approval emails stop until the cool-down resets or the limit is raised.
- Known bug: emails sent after a reassignment may contain the extra word "null" in the body — ignorable.

## 7. Slack

Child: `ind.approvals_slack_considerations.htm`

- A completed work item cannot be reviewed again, regardless of channel.
- Group / queue steps: each active member gets a DM, or the step posts to a Slack channel (Send Approval Notification to Slack Channel + Slack Channel ID). No active members → no notification. Flow Approval Processes cap at 100 active members (not unanimous AA group steps).
- Dynamic Approval Notifications AI summary is in DMs only, not channel posts.
- **Delegates do not receive approval notifications in Slack.**

## 7a. Delegation

- Turn on: Setup → Feature Settings → Approval Settings → **Advanced Approval Delegation**. Once on, delegations configured on User records no longer apply — reviewers create **Approval Delegation** records (App Launcher → Approvals → Manage Approval Delegations).
- `ApprovalDelegation` fields: `DelegatedFromUserId`, `DelegatedToId` (user, group, or queue), `StartDate` (must be in the future), `EndDate` (blank = indefinite), `Comments`.
- Delegate user must be active; a group/queue must have ≥ 1 member; no self-delegation; date ranges for the same approver can't overlap; records can't be deleted — end early by updating `EndDate`.
- Delegates receive email when work items are assigned/reassigned; no Slack.
- List views: Approval Delegations from Me / for Me / All; **Delegated Approval Work Items** on Approval Work Item.

## 8. Preview Approvals

Child: `ind.approvals_preview_feature_limitations.htm`

- Preview works **only with the Autolaunched Flow Approval Process (No Trigger)** flow type.
- Steps with entry conditions based on runtime/async evaluations (e.g. subflows in background steps) are **not shown** in preview. Workaround: set **mock output values** for those evaluations in Flow Builder.
- Preview treats all referenced steps as required dependencies — **does not distinguish AND vs OR** (step starting after A OR B previews as dependent on both).
- Input variables cannot be passed manually during preview — configure **default values** in Flow Builder.
- Dependencies between steps in **different chains** are not shown; steps still appear in sequential order.
- Internal error during preview → verify every stage has a valid exit path and **no steps are assigned to approvers of type Resource**.

## 9. Smart Approval Limitations

Child: `ind.approvals_smart_approval_limitations.htm`

- **Evaluation flows:** using an evaluation flow as entry/exit condition in ANY approval step marks the ENTIRE flow ineligible. Fix: put conditions directly in the workflow.
- **Decision nodes:** a decision node before a stage + "When the stage starts, the step starts" condition makes the flow ineligible. Fix: move the decision criteria into the step's entry conditions.
- **Data types:** approval conditions must use Number or Text to be eligible for auto-review.
- **Trigger requirement:** the preceding submission's status must be **Rejected or Recalled** for a resubmission to be evaluated.
- **Version dependency:** if the active flow definition version changed between original submission and resubmission, Smart Approval is not considered — resubmission must run the **same flow definition version**.
- **NOT operator** in custom entry logic marks the step ineligible — rebuild with positive conditions only.
- **Reassignment:** reassigning a work item during the original submission's execution marks the resubmission ineligible — manual review required.
