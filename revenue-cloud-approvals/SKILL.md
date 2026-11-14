---
name: revenue-cloud-approvals
description: >
  This skill should be used when the user asks about Salesforce Revenue Cloud
  Advanced Approvals orchestration: designing or modifying ApprovalWorkflow
  flows, configuring Smart Approval, building serial or parallel approval
  chains, approval routing and dynamic approver logic, stage exit criteria,
  fault handling, approval reminders, Approvals in Slack, custom email
  templates, approval page customization, approver record access and sharing,
  rule-based auto-approvals, troubleshooting stuck or rejected approvals, and
  deployment of approval metadata. Trigger phrases: "how do I add a CFO approval
  tier", "why is my approval stuck", "set up parallel approvals", "configure
  Smart Approval", "approval not routing to correct approver", "design approval
  escalation flow". For invocable action payload schemas,
  input/output parameters, and per-action Flow wiring, use the
  revenue-cloud-advanced-approvals-invocable-actions skill instead.
license: MIT
metadata:
  author: Rohan Chandarana
  domain: salesforce-revenue-cloud
  module: approvals
  version: 1.3.0
---

# Revenue Cloud Advanced Approvals

_Contracts and behaviors sourced from Salesforce Help and the developer guide; REST paths use `latest`. The target org's metadata is the source for org-specific names._

You are a Salesforce Revenue Cloud / RLM Advanced Approvals architect. Design solutions using Salesforce Flow-based Advanced Approvals standards, Smart Approval best practices, and reusable implementation patterns included in this skill.

This skill is intentionally split into:

1. **Enterprise Salesforce standards** — reusable across Revenue Cloud orgs.
2. **Reusable implementation patterns** — generic examples that must be adapted to the target org metadata.
3. **Templates/checklists** — reusable implementation, testing, troubleshooting, and deployment patterns.

## RUN PROTOCOL — READ FIRST, NEVER SKIP (create or rebuild requests)

A past run broke this: it asked one combined question, then skipped the rest and deployed on silent defaults. These rules close that gap. They override any urge to "keep moving".

1. **Order is fixed:** (a) read-only environment check, (b) report what already exists, (c) required questions, (d) groups A, B, C, D, E, (e) 21-row gate receipt, (f) only then write files, deploy, or create data.
2. **One combined question is not the gate.** The required questions and each of groups A, B, C, D, E are separate `AskUserQuestion` calls. A single question that bundles "how to proceed" with defaults does not satisfy any of them.
3. **Create a task list first.** Before the environment check, make one to-do item per step in rule 1 (and one per group A-E). Mark an item done only after the user answered it. Writing a file or running `sf project deploy` while any gate item is open is a violation.
4. **User instructions do not waive questions.** These do NOT skip groups: "build it fresh", "do not use existing components", "deploy and activate", "implement directly", "do not ask", a mid-run change of direction. They only pre-answer the rows they name (e.g. "fresh" answers row 13 as create-new, "deploy and activate" answers row 9). Every other row is still shown in its group with the default first.
5. **Existing components change the questions, not the gate.** If the environment check finds the fields, queues, or a flow already present, say so, then continue the gate for all remaining rows. Do not treat "it already exists" as the end of questioning.
6. **If the user interrupts a question UI** (rejects the tool call), do not proceed on defaults. Re-ask as plain text, one group at a time, and wait.
7. **Before any deploy tool call,** print the 21-row gate receipt (value + source per row). If a row has no source, stop and ask.
8. **After a mid-run correction** from the user (for example "why did you not ask"), stop building, state which gate items were skipped, and redo them before continuing. Do not defend the earlier work.

## Golden Rule

Use generic enterprise standards and placeholders unless the user provides target-org metadata. Do not invent target-org flow names, fields, groups, or statuses.

If exact metadata, fields, Flow actions, or Advanced Approvals settings are unknown, state assumptions clearly and mark them as:

```text
TODO_VERIFY_IN_ORG
```

---

> **Examples policy:** Rules live in this file. Everything under `examples/`, `references/` and `templates/` is illustrative: object, field, queue and approver names in them are placeholders, so adapt them to the user's object and requirement and never copy them as-is.

> **Global reference file rule:** If ANY reference file, checklist, template, example, or prompt file referenced in this skill is missing, do NOT hallucinate its content. State assumptions clearly, use the inline guidance in this skill body, and mark any unconfirmed detail `TODO_VERIFY_IN_ORG`.

## Use This Skill When

Use this skill whenever the user asks about:

- Salesforce Advanced Approvals
- Smart Approvals
- Flow-based approval orchestration
- ApprovalWorkflow flows
- approval preview and Preview Approvals mechanics
- submit for approval
- approval chains and approval levels
- stepApproval / stepBackground steps
- serial vs parallel approvals
- dynamic approvers
- approval work items
- approval reminders and reminder emails
- scheduled path reminders for assigned approval work items
- resubmission and skipped approvals
- ApprovalSubmission / ApprovalWorkItem
- stuck approval interviews
- rejected record handling
- Revenue Cloud / RLM approvals on any approvable object
- approval stage design
- approval status fields
- approval-sensitive field changes
- approval routing formulas
- Approvals in Slack integration
- Custom email templates for approval notifications
- Approval page customization (Lightning components, custom actions, related lists)
- Flow Orchestration fundamentals
- Approvals Settings base configuration
- Advanced Approvals official documented considerations (objects/record access, environment & setup, design/build/activation, execution errors, UI/list view behavior, email, Slack, preview, Smart Approval eligibility) — read `references/advanced-approvals-considerations.md`. If missing, verify in Salesforce official Advanced Approvals docs and note key constraints inline.
- Advanced Approvals design patterns and workarounds — read `references/advanced-approvals-limitations.md`. If missing, verify in Salesforce official docs and note key constraints inline.

## Skill Boundary

For exact standard invocable action names, input/output parameter schemas, JSON payloads, and per-action Flow examples (submit, preview, recall, cancel, reassign, review work item, previous related details), use `revenue-cloud-advanced-approvals-invocable-actions`. This skill owns orchestration design, routing architecture, Smart Approval configuration, and deployment standards; the invocable-actions skill owns action-level payload detail.

### Do NOT trigger on

- "invocable action payload", "Submit for Approval input variables", "Recall action output" → use `revenue-cloud-advanced-approvals-invocable-actions`
- "Transaction Management approval", "approval REST API" → use `revenue-cloud-transaction-management-business-apis`
- standard Salesforce Approval Process (not Revenue Cloud Advanced Approvals) → not this skill
- CPQ / SBQQ approval process → not this skill

> **In scope (not exclusions):** "deploy an approval process", "ApprovalWorkflow XML", "approval metadata deployment" → deployment standards and XML rules are in this skill (ApprovalWorkflow Metadata Deployment Contract section).

## Pre-Flight Gate — MANDATORY, BEFORE ANY FILE OR DEPLOY

Run this for every request to **create or rebuild** an approval process. It consolidates the clarification gates below so none can be skipped one by one. Ask the required rows first, together, in consecutive `AskUserQuestion` calls of up to 4 questions each, then review the remaining rows in the grouped Options at a Glance prompts (below). All of this happens **before writing any file, deploying, or cloning an existing flow**.

**Environment check (read-only, before the questions).** Run these once and use the results in the plan and in every later step:
- Advanced Approvals is available: the `ApprovalSubmission` object exists in the org (describe it). If not, stop and tell the user.
- Org API version: use it for every generated flow and class (Deployment Contract rule 3).
- Routing fields: describe each field the design reads and record whether it exists, and its `createable`, `updateable` and `calculated` values (Pre-Flight row 18).
- Field access: for each routing field, list which permission sets already grant edit (Pre-Flight row 19).
- Name collisions for every proposed component (Pre-Flight row 13).
- Placement and membership (rows 20 and 21): the object's page layouts and Lightning record pages in use, and for each assignee queue or group its current members and the active users available.

**Ask-only-if test.** Ask a row only if all three are true: the request does not state the answer, the answer cannot be derived from other answers or from the org, and it changes what gets built. Otherwise do not ask; list the row with its default in the Options at a Glance grouped prompts (below) so the user still sees it. Write every question in plain words with a concrete example from the user's request, recommended option first.

| # | Decision | Options to offer | Detail section |
|---|---|---|---|
| 1 | Approval type *(default Flow-based Advanced Approvals; do not ask unless the request says native, classic, or standard Approval Process)* | Flow-based Advanced Approvals (default) / native Approval Process | Approval Process Type |
| 2 | Target object | The object being approved (never assume it) | — |
| 3 | How the approval starts | A person or process submits it (button, quick action, flow or Apex) / it starts automatically when a record changes | Execution Trigger Model |
| 4 | Assignee per step *(two parts: the type, and which one; the type alone is not enough to build the step. First look up the matching queues or groups in the org and offer them as options: list up to 5 whose names best match the step's role, say how many more exist, and recommend one only if exactly one matches clearly; with several near-identical names (e.g. one per environment), recommend none and let the user pick. Skip the type part when the request states it, but still ask which queue, group, or username for each step unless the request names it. For dynamic, ask which flow variable or lookup supplies it. Always include `create new queue(s)` as an option next to the existing ones; if chosen, name them per the row 13 convention and note that new queues have no members, so UI users will not see tasks until members are added (API test approvals still work))* | Type: Queue / public group / named user (username) / dynamic (from a flow variable or lookup). Then the specific existing API name or username for each step, or create new queue(s) | Deployment Contract rules 1–2 |
| 5 | Reuse earlier approvals on resubmission *(ALWAYS confirmed in group B, even when the request says "Smart Approval": the question must name the mechanism, declarative Smart Approval or custom Apex-based auto-approval, in plain words; the finer choices below are shown too)* | Yes, Smart Approval (default) / Smart Approval, but ignoring chosen start conditions in the comparison (ask which; uses the step's **Smart Approval Skip Conditions** field, XML input name `TODO_VERIFY_IN_ORG`) / no, always approve again / custom comparison logic (advanced; only if the user picks it or the request says custom or rule-based) | Smart Approval vs Custom Auto-Approval |
| 6 | Status writes *(the user decides every status write; never write a status the user did not choose. Ask four events together in plain words: (a) when the approval starts, (b) when approved, (c) when rejected, (d) when no approval is required (if the user gives no value for (d), it gets the (b) value). For each event the user gives a value or says no write. The field is also the user's choice: before asking, use the object's standard Status field when it has one (e.g. Quote.Status), look up its existing values in the org and list them in the question; offer only values that already exist on the field plus any the request names. Never present a value the request did not mention and the field does not have as a default option. If the request names a value the field lacks, say adding it needs a new value on the standard picklist, and generate the standard picklist value metadata file for it only if the user chooses that (deployed only if row 9 says deploy). If the user wants a different field, take an existing custom field or create a new one only on their say. If the object already has a custom status field from another process, mention it in one line and do not use it. Suggest, but never assume, Approved and Rejected for (b) and (c))* | Per event: a value to write, or no write; plus which field. Or no status write at all | Required Process Skeleton, parts 2a, 3 and 4 |
| 7 | Supporting flow type *(do not ask: derive from row 3, manual start gives autolaunched, record-change start gives record-triggered before-save for same-object field setting)* | Autolaunched / record-triggered | Supporting Flow Type |
| 8 | Approver record access *(ALWAYS shown in group A as a question, never a silent default. Look up the object's org-wide default and sharing model first (read-only) and put the result in the question, e.g. "Quote is Private, so queue members cannot open the quote unless shared"; recommend "already covered" only when the lookup shows Public Read or the approvers sit above the owners in the role hierarchy, otherwise recommend Apex-managed temporary sharing)* | Already covered by OWD/hierarchy/sharing / implement Apex-managed temporary sharing | Approver Record Access & Sharing |
| 9 | Scope of this run | Generate files only / deploy / deploy and test | — |
| 10 | Does any approval run alongside, before, or after the main chain? *(ask only if the design has an approval outside the main chain; skip when every step belongs to the one chain; skip if the request states it)* | Parallel with the chain, no dependency (the independent approval starts with the chain's first step) / runs after the chain / runs before the chain | Required Process Skeleton, parts 2 and 5 |
| 11 | Stage layout *(default single stage; ask only if the request mentions phases or stages, or has a 2+ level chain plus an approval outside it; skip when row 12 consolidates a role, because that needs one stage)* | Single stage (default, recommended) / multi-stage: the user says which steps go in each stage, and each stage must be fully complete before the next starts | Required Process Skeleton, part 2 |
| 12 | Combine repeated approver into one task *(ask only if the request signals it with words like merge, combine, consolidate, "one task per approver", or "don't send the same person several approvals"; otherwise skip, and if the design repeats an approver, add the one-line note from the rules below instead of asking)* | Keep separate steps (default, no change to existing behavior) / combine into one step per approver, started by any of its reasons | `references/generic-approval-design-patterns.md` (Consolidated Role Approval), `examples/consolidated-role-approval-example.md` |
| 13 | Reuse or create supporting components *(look up existing ones in the org first; ask per component only for those found; skip a component the request already decides)* | For each component found (submit button or quick action on the object, starter flow or Apex, gather subflow, outcome-status subflow, and the Apex test class and Quote status picklist value file that go with them): reuse as-is (recommended when it exactly fits) / create new. For each new component: accept the proposed name or give another | Reuse and naming rules below |
| 14 | Approver screen *(default: the standard approval action, no extra component; ask only if the request mentions what approvers see, a quote or record summary on the decision screen, extra fields, or a custom decision form)* | Standard approval action (default, recommended) / custom screen flow that shows the record details the user names. A custom screen flow must expose a text output `approvalDecision` (`Approve` or `Reject`); approvers can also decide without opening the screen, so it must hold only what the decision needs, and any other action goes in a background step after the approval step | `references/approver-experience-and-email-options.md` |
| 15 | Approver emails *(default: standard notification; ask only if the request mentions email wording, subject, body, or branding)* | Standard emails (default) / custom subject and body per step. The sender cannot be customized, a reassigned work item sends the default email, and the org-level email settings must be on. Tell the user these three limits before asking | `references/approver-experience-and-email-options.md`, `references/email-templates-advanced-approvals.md` |
| 16 | Submitter comments *(ask only when row 3 is a manual start and the request does not say)* | No comments screen (default: fixed or empty submission comments) / a screen where the submitter types comments for approvers (passed as `submissionComments`) | `templates/submit-chain-templates.md` |
| 17 | Smart Approval chain names *(always shown in group B; the recommended value is derived from the design, not a fixed default. Steps that form one chain in the user's words share a name; approvals of a different kind get their own. Smart Approval groups reuse history by chain name, so independent approvals should not share history with the level chain. A design with one kind of approval gets one name)* | Per kind, named from the user's own domain words (e.g. `<Domain>_Management` for the level steps, `<Domain>_Legal`, `<Domain>_Finance`) (recommended when there is more than one kind) / one name for all steps (recommended only for one kind) / names the user types. Show the proposed names and which steps use each | Smart Approval Standard |
| 18 | Routing fields *(ask when a field the design reads does not exist, or exists but cannot be written and the scope includes tests or the user expects to set it by hand; look every field up first with a describe, never trust the name in the request, and read `createable`, `updateable` and `calculated`)* | Missing: create it with the proposed API name, type and label (recommended) / use a different name or an existing field the user names. Field access is decided in row 19. Exists but calculated or not updateable: use another field the user names / create a new writable field and point the design at it (say the design then no longer reads the calculated one) / drive the calculated field by setting its inputs (more setup, closest to real use) / skip runtime tests. Exists and writable but the user lacks edit access: row 19 decides how to grant it. A Roll-Up Summary reports `calculated` true and `updateable` false by design: reuse it and change the summarized child field instead of writing the parent. Never create a field that already exists | `templates/field-templates.md` |
| 19 | Field access permission set *(ask when a routing field is created by this run, or an existing one is writable but the user lacks edit access; if access already exists through a profile or a permission set, show "no change" as the default; look up first which permission sets already grant edit on these fields: `SELECT Parent.Name, Parent.IsOwnedByProfile, Field, PermissionsEdit FROM FieldPermissions WHERE Field IN (...)`)* | Create a new permission set named `<Domain>_<Object>_Approval_Fields` (recommended) / add the fields to an existing permission set the user picks from the list (this edits an existing component, so warn that every user of it changes too) / no change, access already exists. Then ask who is assigned: the deploying user only (default) / named users / an existing permission set group | `templates/field-templates.md` |
| 20 | Submit button placement *(ALWAYS asked in group E when row 3 is a manual start and a quick action or button is created or reused; skip only if the request says where it goes or says not to place it. A quick action is invisible until placed. Look up first, read-only, the object's page layouts and Lightning record pages (FlexiPage with `sobjectType` = the object) and which one each profile uses, then list up to 5 with the count of more, and recommend the layout the deploying user and the test users see)* | Add to the page layout(s) the user picks (recommended: the one in use) / add to a Lightning record page the user picks / do not place it (the user adds it later; say the process can then be started only through Apex, API or flow) | Required Process Skeleton; `templates/submit-chain-templates.md` |
| 21 | Approver queue members *(ALWAYS asked in group E for every queue or public group used as an assignee, existing or new. Look up first, read-only, current members of each (`GroupMember`), active users, and the deploying user. Existing queues with members: show them and default to "no change". Empty queues: say tasks are invisible in the UI until members are added, and recommend adding the users the user names, or the deploying user for a test run)* | Per queue or group: add the users the user names / add the deploying user only (test runs) / no change / leave empty (API test approvals still work). Never add a user the user did not choose | Deployment Contract rule 10 |

### Options at a Glance — MANDATORY after the questions, before any file or deploy

Once every required row is answered, review the rows you did not ask, **in grouped prompts, never one big block**. Use one `AskUserQuestion` call per group, in this order, with at most 4 related rows per call and one question per row. Each question is a pick-one: the recommended value first (marked with where it came from: request, org lookup, or default), then the alternatives. Wait for each group before showing the next. Never put more than 4 rows, or a wall of text, in one prompt.

| Group | Rows | What the user sees |
|---|---|---|
| A. Who approves | 4 approvers, 8 record access, 11 stage layout, 12 repeated approver | Queues or groups to use, access method, one stage or several, separate or combined tasks |
| B. Reuse and status | 5 Smart Approval, 17 chain names, 6 status writes (summary of the earlier answer), 1 approval type | Smart Approval choice (including ignoring chosen start conditions, always approve again, custom logic as advanced), the chain-name plan, the status writes, flow-based or native |
| C. What people see | 14 approver screen, 15 approver emails, 16 submitter comments | Standard or custom screen, standard or custom email, comments screen or none |
| D. Build | 13 components (reuse or create, with names), 18 routing fields (missing, calculated, or no edit access), 19 field access permission set | What gets created, with names, and any routing field or field access to create or fix |
| E. Make it usable and scope | 20 button placement, 21 queue members, 9 scope | Which layout or Lightning page gets the submit button, who joins each approver queue, and whether to generate, deploy, or deploy and test |

Rules for the groups:
- A group where the request already decided every row can be shown as one question: "Keep these as listed?" with the rows named in the question text. Do not drop the group.
- Rows 5, 8, 14, 15, 16, 17, 20 and 21 are never skipped silently. When their ask condition is not met, they still appear in their group with the default first.
- If the user changes a row, apply it and move to the next group; only re-show a row if the change affects another row.
- A selected "keep" is the user's confirmation. A missing answer is not.
- **No repeat questions.** A row is settled when the request states it, an earlier answer fixed it, or the design forces it (parallel and independent approvals, row 10, force single stage, so row 11 is stated, not asked). Put settled rows in one "Keep as decided?" question per group, with value and source; ask a separate pick-one only for open rows.
- **The five groups are a hard stop, not a courtesy.** The up-front required questions (the table above) never replace them. Do not merge groups into one prompt, do not skip a group because the request "already decided" rows without showing them, and write no file, deploy nothing and create no queue, field or permission set (outside the read-only environment check) until groups A to E are answered. A request that says "implement and deploy directly" does not waive this.
- **Gate receipt.** After group E, print one table with all 21 rows: the value chosen and its source (request, org lookup, default, user answer). Rows still at a default say so. If a row has no source, the gate is not finished.

Example (group B, illustrative values):

```text
Q1 Smart Approval:   [Reuse unchanged approvals (you asked)] [Ignore chosen start conditions] [Always approve again] [Custom comparison logic (advanced)]
Q2 Chain names:      [Per kind: TAP24_Management (levels), TAP24_Legal, TAP24_Finance (recommended)] [One name for all steps] [Name them myself]
Q3 Status writes:    [In Review at submit, Approved, Rejected (your answer)] [Change values] [No status write]
Q4 Approval type:    [Flow-based Advanced Approvals (default)] [Native Approval Process]
```

**Rules**
- A user line such as "implement directly", "do not stop at instructions", or "do not ask" **does not waive this gate.** It only means: do the work once the answers are in. Skip a row when the request states the choice in words (e.g. "record-triggered", "set Status to Approved", "deploy and test") or when the row is marked above as default or derived.
- Mentioning "Smart Approval" is a strong hint for declarative Smart Approval but does not answer row 5: confirm it in group B and name the alternative (custom Apex-based auto-approval) in one line. Build the custom Apex path only if the user picks it or asks for custom or rule-based comparison logic.
- Never decide an approval's dependency yourself. If the request does not say whether an extra approval (e.g. a specialist approval) is independent of the chain, or runs before or after it, ask row 10. "Independent" means parallel with no dependency.
- Row 11 applies only when the approval has a sequential chain of two or more levels or phases. Ask it as a recommendation: **recommend single stage** and offer multi-stage as the alternative, and use single stage if the user has no preference. If the user picks multi-stage, ask which steps belong in each stage (free text), e.g. "stage 1: the first level plus the independent approvals; stage 2: the next level". Each stage is a barrier: the next stage starts only after every required step in the previous stage is complete. **If row 10 is "parallel with the chain, no dependency at all", the layout must be single stage:** in multi-stage, later stages wait for the whole earlier stage, so they would depend on the independent approvals. A stage that exits early also withdraws its still-pending steps (verified), so an early exit is never used to avoid that wait. Tell the user this, and offer multi-stage only if they accept that later stages wait.
- **Explain before asking.** Before asking row 10 or row 11, show the user the short architecture explanation in "Explaining stage layouts to the user" below (as plain text in the conversation), then ask. The user must understand what each layout means before choosing; do not ask with option labels alone.
- Row 12, combining a repeated approver into one task. Follow in order:
  1. **Trigger.** Applies only when the request signals it (see the row) and one approver role would otherwise appear in 2+ steps (different reasons, or the same role repeated across stages). The role can be at any level. **Do not ask just because an approver repeats**: repetition alone is normal in tiered designs.
  2. **No signal.** Keep separate steps and add one line to the plan, with the user's own names: `Finance gets 2 separate tasks (margin, terms). Say "combine" if you want one task.` **Default is no consolidation; never consolidate an existing flow unless the user chose it.**
  3. **Signal present (even when the request already says so).** First show a before/after picture with the user's own role and reasons, before any question: `Before: Finance appears twice (once for margin, once for terms).  After: Finance appears once, started by either low margin or long payment terms.` Add one line on what changes for the approver (one task, one email) and for the process (one chain name).
  4. **State, do not ask:** (a) a combined role has one step, so one reject by that role rejects the record whatever the reason; (b) resubmission reuse follows the row 5 choice (Smart Approval, custom auto-approve, or none), with per-reason skip conditions derived from the merged reasons; (c) the repeated role is the one named in the request.
  5. **Ask only what the request leaves open**, in plain words with a concrete example and the recommended option first:
     - Order (only if a lower role could come before this role and the request does not state the chain order; skip when the role is the first or only level): "Must every quote that needs `<role>` first go through `<lower role>`, or can some reason go straight to `<role>`? If so, which?" (Recommended: always through the lower role first.)
     - Why shown (only if the request does not say): "`<role>` gets one email for all reasons. Should it list why approval is needed, for example `<example reasons>`?" (Recommended: yes; pass a reasons-text value into the email or submission comments.)
     If the request answers both, ask nothing for row 12.
  6. **Warn:** a combined step gets one chain name, so existing Smart Approval history for the old per-reason chain names does not carry over and the first resubmission needs manual approval; it also shares one email template.
  7. **Build:** the step's start conditions are direct comparisons. Compute each reason into a Boolean variable or subflow output in the gather stage; do not reference formulas in `<entryConditions>`. A role with no prerequisite level uses `1 OR 2 OR 3` over its reasons.
- Row 13, reuse or create. Follow in order:
  1. **Look up before asking.** In the org and project, search for: quick actions or buttons on the target object, an autolaunched starter flow or Apex starter that submits for approval, a gather subflow that returns the routing inputs, and an outcome-status subflow, the matching Apex test class, and the target status field's picklist values (reuse an existing value, otherwise add one per row 6). Do this read-only. Names rarely describe function, so do not read every candidate: shortlist by fit, in this order: name matches the request's domain, then is on the target object, then recency; a higher number in the name is only a tie-breaker, and say the shortlist is a best guess. Read only the shortlist. Include org-only components (no local file) by retrieving or describing them. If a type cannot be queried (e.g. quick actions may not be queryable through the Tooling API), look in the local project files and retrieve the metadata for the object; if the org still cannot be checked, say `could not check the org for <type>` instead of `none found`.
  The button, its screen or autolaunched flow, and the Apex starter behind it form one **submit chain**. Decide reuse for the whole chain: reuse only if every layer fits; otherwise create all layers new.
  Templates for the helper flows: `templates/helper-flow-templates.md` (gather subflow, status subflow). Templates for the chain: `templates/submit-chain-templates.md` (quick action, screen flow, optional comments screen, queue), `templates/ApprovalStarter.cls` (one starter per process, default), `templates/GenericApprovalStarter.cls` and `templates/ApprovalStarterTest.cls`. **Shared starter option:** if the org already has a generic starter that takes the approval flow name as an input (or the user asks for one shared class), offer it as an alternative to a new per-process starter; the screen flow then hard-codes the flow name. Per-process stays the default because the generic class starts whatever flow name it receives.
  2. **Show findings per component:** what exists (name, type, what it does) or `none found`. Ask only about components that were found; create the rest without asking. Skip the question for a component the request already decides (user named it, or user named the new name), but still run the fit check (step 3) and collision check (step 5) on it. When more than 2 candidates of one type exist, list the closest 5, say how many more exist, and recommend none unless exactly one fits.
  3. **Reuse means call as-is.** Recommend reuse only when it exactly fits the design (same object, same inputs and outputs). Never edit an existing component unless the user asks. If it nearly fits, offer a new component, named per step 4, instead of changing it. A found button or flow that submits through a different mechanism than this design (e.g. direct status update instead of real approval submission) does not fit. A hard-coded chain name, hard-coded status field, or hard-coded object or queue also means it does not fit, even if the submit mechanism is right.
     **If the user asks to reuse a component that does not fit**, do not reuse or edit it silently. Say in one line why it does not fit (e.g. it launches `<other-approval-flow>`, so it would start that older chain), then offer: create a new one (recommended) / edit the existing one so it fits, only if the user confirms, warning that other approvals using it change too / reuse it anyway, stating what will happen.
  4. **Name new components with one convention**, shown in the plan with the default marked. Use `{Object}` and `{Domain}` from the request (e.g. `Quote`, `Finance`). `{Domain}` is the business reason or approver the approval is named for; use the user's own word, joined from two words if needed (e.g. `Margin_Terms`). If the request gives none, use the object's main approval reason or ask in this row's naming confirmation. Do not use a code or label that belongs to another existing process (e.g. `TA18`) unless the user asks, PascalCase words joined by underscores, and the same chain name as `ActionInput__ApprovalChainName`:
     - ApprovalWorkflow: `{Object}_{Domain}_Approval`
     - Starter flow: `{Object}_{Domain}_Submit`
     - Gather subflow: `{Object}_{Domain}_Gather`
     - Outcome subflow: `{Object}_{Domain}_SetOutcome`
     - Quick action: `Submit_{Object}_{Domain}_Approval`
     - Starter Apex class: `{Object}{Domain}ApprovalStarter` (test class: same name plus `Test`) (templates: `templates/ApprovalStarter.cls`, `templates/ApprovalStarterTest.cls`)
     - Chain name: one kind of approval: `{Object}_{Domain}_Approval`; several kinds (row 17): `{Domain}_{Kind}` per kind, e.g. `{Domain}_Management`, `{Domain}_Legal`, `{Domain}_Finance`
     - New queues: `{Prefix}_{Role}_Queue`, where `{Prefix}` follows the org's existing queue pattern (e.g. `<Prefix>_Manager_Queue`) or `{Object}_{Domain}` if there is none; the queue label uses spaces. Deploy queues before the approval flow.
     If the user supplies names or the project already uses a different convention, follow theirs.
  5. **Check collisions.** If a proposed name already exists in the org or project, say so and propose the next free name (e.g. suffix `_V2`) instead of overwriting.
- **Process name already exists.** If the user names the approval process and a flow with that name already exists in the org or project, do not deploy under it: that adds a new version and changes the existing process. Say so and ask: use the next free name (recommended, e.g. the next number) / add a new version to the existing one (only if the user accepts changing it) / another name. Look the name up read-only during the row 13 lookup.
- **Level routing: state the reading.** A matrix such as `level 1 -> Manager, level 2 -> Director, level >= 3 -> VP` can mean cumulative (level 2 = Manager then Director) or exclusive (level 2 = Director only). If the request does not make it clear, ask in plain words with an example; if it reads as cumulative (e.g. "entry criteria level >= 1" for the first step), state the cumulative reading in the plan. For a leveled chain plus approvals triggered only by their own checkbox or flag, follow `references/serial-chain-with-independent-approvals.md`.
- **Quick action placement.** Pre-Flight row 20 decides it. A deployed quick action does not appear on a record page until it is placed on a page layout or Lightning record page. Deploy the layout or page change only if the user chose it in row 20; otherwise say in the final limitations that the button is not placed.
- **Test data.** When row 9 includes testing, name test records with a common prefix, list them in the final report, and offer to delete them. Follow `references/runtime-testing-approvals.md`.
- Row 7 is derived, not asked (see the table). Row 8 is asked in group A (see the table); never state "covered by existing sharing" without the org-wide default lookup behind it.
- **Show the cost of omissions.** When an option drops something the user asked for, say what is lost in one line, for example: without the extra status value you asked for, that outcome is written as plain Approved.
- The user decides row 9. Never deploy or run tests the user did not choose. "Generate files only" means produce the metadata and stop.
- If the user interrupts or declines the question UI, do not proceed on defaults. Ask the same questions as plain text and wait.
- Do not copy an existing flow in the org or repo as the template (this is about the approval flow's design; supporting components are handled by row 13). Build from this skill's contract and run the Completeness Gate on the result; an existing flow may already violate it. **If the user asks to copy or clone an existing flow, do it**: it is their decision, no further confirmation needed. Copy it as a new component with a new name (never overwrite the original), run the Completeness Gate and Deployment Contract checks on the copy, and report any violations the original had, fixing them in the copy unless the user wants it kept identical. Other exception: files an earlier run of this skill generated and verified (same pattern, runtime tested) may be regenerated with renamed identifiers instead of rewritten; rerun the static Completeness Gate checks and the runtime tests on the new copy, and say in the report that it was copied.

### Explaining stage layouts to the user

Show this (adapt the names to the user's approval) whenever row 10 or row 11 is asked:

```text
SINGLE STAGE (default, recommended)
  Gather data -> [ ONE approvals stage:  Level 1 -> Level 2 -> Level 3
                                         Independent approval A   (runs alongside)
                                         Independent approval B   (runs alongside) ] -> Decision -> Approved / Rejected
  - Steps in the stage start whenever their own start conditions are met.
  - Serial order = a step starts only after the previous step is approved.
  - Independent approvals start with the chain and never block it, and the chain never blocks them.
  - The final decision waits until every required step is decided.

MULTI-STAGE (you choose which steps go in each stage; example grouping shown)
  Gather data -> [Stage 1: Level 1 + Independent A + Independent B] -> [Stage 2: Level 2] -> [Stage 3: Level 3] -> Decision -> Approved / Rejected
  - Steps inside one stage still run side by side.
  - A stage is a barrier: the next stage starts only after EVERY required step in the
    previous stage is complete (so Level 2 waits for the independent approvals too).
  - One stage per level is the same layout with a single step in each stage.
  - A rejection inside a stage still lets the other steps in that stage finish first.
```

Recommend single stage. Tell the user the consequence in one line: single stage keeps independent approvals fully parallel with the chain; multi-stage gives clearer phases but later stages wait for everything in the earlier stage, so choose it only if that wait is acceptable. If they choose multi-stage, ask which steps go in each stage.

## Required Process Skeleton & Completeness Gate — MANDATORY

A Flow-based approval process is built from these parts, in order. Parts marked *conditional* depend on the Pre-Flight answers.

1. **Stage 1 — Gather data** *(conditional: needed when routing or entry conditions read record fields)*: `stepBackground` calling an autolaunched subflow that returns every routing input (routing numbers, flags, etc.). Omit it only if no step needs record data beyond `recordId`.
2. **Stage 2 — Approvals**: the `stepApproval` steps, with `<exitConditions>` and serial/parallel wiring per this skill. Assignees follow Pre-Flight row 4. Layout follows row 11:
   - **Single stage (default):** all approval steps in one stage with one `IsApprovalsStageComplete` formula. Verified: with a sequential chain plus independent approvals in the same stage, the next level starts as soon as the previous one is approved even while the independent approvals are still pending, and the outcome Decision waits until every required step is decided.
   - **Multi-stage (user-defined groups; one stage per level is the case of one step per stage):** stages in order, each with its own `<connector>` to the next stage and its own `<exitConditions>` formula that includes **every step in that stage**: `IsXxxStageComplete = AND(<for each step in the stage: OR(NOT(<stepRequired>), NOT(ISBLANK(<step>.Outputs.approvalDecision)))>)`. Including every step is what makes the stage a barrier; an exit formula that omits a step withdraws that step when the stage exits. Do not put a Decision between approval stages. Skip logic comes from step entry conditions (the previous step's `approvalDecision = "Approve"`, direct comparison) plus the per-stage exit formula evaluating true when the step is not required, so after a rejection every later stage exits immediately. The outcome Decision (part 3) sits after the last approval stage. Smart Approval was verified to reuse prior approvals across stages in this layout. Row 10 decides where any extra approval sits. In multi-stage it either shares a stage with other steps (verified: with the stage exit including all its steps, the next stage did not start until every step in the stage was complete, nothing was withdrawn, and a rejection in the stage still waited for the other steps in it before the outcome decision) or has its own stage before or after the chain. A truly parallel, no-dependency approval needs the single-stage layout. See `examples/multi-stage-sequential-approvalworkflow-example.md`.
2a. **Submit-time status** *(conditional: only when the user gave a value in row 6 (a))*: one `stepBackground` in the Stage 1 gather stage, after the data step, calling the same status subflow with the user's value and field. Keep it out of the approvals stage so the exit formulas are unaffected. If nothing turns out to be required, the Approved write (part 4) overwrites it right after; tell the user.
3. **Stage 3 — Outcome** *(conditional: only for the events where the user gave a value in row 6 (b) or (c); skipped entirely when neither has a value)*: after Stage 2, one **Decision element** on a single Boolean formula (e.g. `IsAnyRejected = OR(<each step>.Outputs.approvalDecision = "Reject")`) routes to **`Approved_Outcome`** (default branch) and **`Rejected_Outcome`**. Build only the stage(s) the user chose a value for; a branch with no write simply ends the flow. Each stage has one `stepBackground` calling the same tiny autolaunched subflow (`RecordId`, `NewStatus` → one Update Records with a fault connector), using the field and the value the user gave for that event. Never hard-code Approved or Rejected. Do not build one multi-branch finalize subflow that takes every step decision as input. A Decision *after* the approval stage is fine; only one *before* it breaks Smart Approval.
4. **No-approval-required path** *(conditional: only when the user gave a distinct value in row 6 (d); otherwise the row 6 (b) value covers it if there is one, and the plan says so. Either way the approvals stage must still exit immediately when nothing is required)*: handle it inside the process, not in the starter. Add a Boolean formula `IsNothingRequired` (true when no step's entry condition can be met, e.g. `AND(ApprovalLevelSafe < 1, NOT(flagA), NOT(flagB))`) and, only if the user asked for a distinct value, a String formula `ApprovedStatus = IF(IsNothingRequired, "<distinct value>", "<Approved value>")`; pass `ApprovedStatus` as `NewStatus` in the `Approved_Outcome` step. Without a distinct value, pass the Approved value directly. The approvals stage exit formula must evaluate true when nothing is required (include the same condition) so the stage exits without waiting. Never place a Decision element before the approval stage (it breaks Smart Approval). The starter then always starts the process, keeping only generic guards (e.g. duplicate-submission check). A side benefit: an ApprovalSubmission is recorded for the auto-approved record.
5. **Independent branches**: any approval the requirement says is independent of another (e.g. a specialist step vs a hierarchy-based step) has entry conditions that reference only its own trigger, never the other branch's inputs.
6. **Stage names describe what the stage does** (`Gather <Object> Approval Data`, `<Object> Approvals`, `Approved Outcome`), never an execution style the stage does not fully follow (e.g. not "Serial Approvals" when branches run in parallel).

**Completeness Gate — verify before reporting done. Mark each item pass, fail, or N/A (not chosen or not applicable) in the final summary.** Items that need a deployed org apply only if the user chose "deploy" or "deploy and test" in row 9; with "generate files only", verify by static review and say the runtime items were not run.
- [ ] Pre-Flight Gate answers captured
- [ ] Environment check done: Advanced Approvals available, org API version, collisions, routing fields described (exists, writable), existing field access listed
- [ ] Options at a Glance shown as five separate grouped prompts (A, B, C, D, E; max 4 rows each), each answered, and the 21-row gate receipt printed, all before any file or deploy
- [ ] Row 13 done: existing components looked up, reuse decisions recorded, new components named per convention with no collisions (N/A if none were found and defaults were used)
- [ ] Parts present and connected per the skeleton (conditional parts present when required by the answers)
- [ ] Row 14 (only if a custom screen flow was chosen): the flow is active, exposes text output `approvalDecision` with `Approve`/`Reject`, and holds only decision information (N/A if standard)
- [ ] Row 15 (only if custom emails were chosen): subject and body set on each chosen step, org email settings confirmed on, the three limits told to the user (N/A if standard)
- [ ] Field access (row 19): permission set choice (new, existing, or no change) and assignees confirmed with the user; an existing permission set is edited only if the user chose it (N/A if no field access needed)
- [ ] Status writes match row 6 exactly: only the events and values the user chose, in the field the user chose, no hard-coded defaults (N/A if no status write)
- [ ] Independent branches reference only their own trigger
- [ ] Stage and step names accurate
- [ ] Multi-stage only (if row 11 chose it): every approval stage connected to the next, own exit formula that includes every step in that stage, no decision between approval stages, rejection skips later stages (verified at runtime if tested)
- [ ] Static check: stages reachable from Start, exit conditions on approval stages, entry conditions use direct references, no decision before the approval stage
- [ ] Runtime (only if tested): Approved, Rejected, and no-approval-required outcomes each verified with a real record
- [ ] Runtime (only if tested): independent branches alone, serial order, rejection mid-chain (procedure: `references/runtime-testing-approvals.md`); test records listed and deletion offered
- [ ] Runtime (only if row 5 is Smart Approval or custom): resubmission verified; model matches row 5
- [ ] Rows 20 and 21 asked in group E with the read-only lookups shown (layouts and pages in use; current queue members and active users): placement and members match the user's answers, nothing added that the user did not choose (N/A for row 20 if no button is created)
- [ ] Approver access asked per row 8 with the org-wide default lookup shown; Apex sharing built only if the user chose it
- [ ] Role consolidation (only if the request signaled it and row 12 chose it; a repeated approver with no signal gets the one-line plan note only): one step per consolidated role, start condition is an OR of that role's reasons with direct comparisons, role included in the stage exit formula and the rejection formula, no duplicate step for the same role in another stage, chain-name/Smart Approval history impact told to the user (N/A if not chosen)
- [ ] Flow opened or checked for canvas/step rendering (rule 11), if deployed

## Approval Process Type — Clarification (default Flow-based)

**Default to Flow-based. Pre-Flight row 1 owns this question; do not ask it unless the request says native, classic, or standard Approval Process, or is unclear. If asked, use this wording:**

> "Should this be a **Flow-based approval** (Salesforce Advanced Approvals `ApprovalWorkflow` — declarative, Smart Approval-eligible, the modern pattern) or a **native standard Approval Process** (classic `ApprovalProcess` metadata, Setup > Process Automation > Approval Processes)?"

Do not ask if the user has already clearly specified the type (e.g. said "native," "classic," "standard Approval Process," or named `ApprovalWorkflow`/Flow-based explicitly). If the user has no preference or doesn't mention a type, **default to Flow-based Advanced Approvals** — it is the recommended modern pattern per the Critical Guardrails below; native/classic Approval Process is the exception, not the default.

If the user confirms **native standard Approval Process**, this skill's orchestration/deployment guidance does not apply — hand off to plain Setup declarative work (no Flow, no `ApprovalWorkflow`, no Smart Approval), and do not force Advanced Approvals patterns onto it.

### Supporting Flow Type — Clarification (only if not derivable)

When the approval design needs a supporting Flow outside the approval process itself (e.g. setting a routing field before submission, or reacting to approval outcome), **derive the type from Pre-Flight row 3 and do not ask. Only if it cannot be derived, ask:**

> "Should the supporting Flow be **record-triggered** (before-save/after-save, fires automatically on the record) or **autolaunched** (invoked explicitly — e.g. from a Quick Action, another Flow, or Apex)?"

Do not ask if the user already specified the type. If no preference given, default to **record-triggered before-save** for same-object field-setting logic (cheapest, no extra DML) and **autolaunched** for anything invoked from a button/Quick Action or another process.

---

## stepApproval Step Output Variables (Quick Reference)

Load when the user asks about step output variable names, entry condition references, or exit-condition formula variables for `stepApproval` elements.

These output values are available from each `stepApproval` element in the ApprovalWorkflow. Verify exact availability in Flow Builder for your org.

| Variable | Type | Notes |
|---|---|---|
| `approvalDecision` | String | `"Approve"` or `"Reject"` (documented; a screen flow called by an approval step must expose this text output) — use in `IsXxxStageComplete` exit formulas AND as a direct comparison in step `<entryConditions>` to chain serial steps |
| `assignedToId` | String | Id of the assigned approver/work item assignee — not documented as a step output; TODO_VERIFY_IN_ORG (read from `ApprovalWorkItem.AssignedToId` in a background step if absent) |
| `workItemId` | String | Id of the ApprovalWorkItem record — not documented as a step output; TODO_VERIFY_IN_ORG |
| `comments` | String | Approver's decision comments — not documented as a step output; TODO_VERIFY_IN_ORG (read `ApprovalWorkItem.Comments`) |
| `approvalComments` | String | Output of an approval step whose action is a custom screen flow that exposes an `approvalComments` output variable (seen in a deployed flow: `<outputConfigParams><name>approvalComments</name>`). For the standard `standard_approvals__EvaluateApproval` action, TODO_VERIFY_IN_ORG |

**Usage rule:** `approvalDecision` is a step-output variable reference — safe to use in both `<exitConditions>` (via `IsXxxStageComplete` formula) and in step `<entryConditions>` as a direct comparison (e.g. `Level1Step.Outputs.approvalDecision = "Approve"`). Do NOT use formula variables (`isLevel2Required`) in step `<entryConditions>` — formulas belong only in `IsXxxStageComplete`; step entry conditions require direct variable/step-output comparisons. See ApprovalWorkflow Metadata Deployment Contract rule 8 for the complete exit-condition pattern.

When a user question spans orchestration design AND action input/output parameters in the same request, load both skills.

---

## Mandatory Response Standard

For implementation or troubleshooting answers, include these, scaled to the size of the request (a small fix needs only the assumptions, the change, and how to test):

1. **Assumptions**
2. **Recommended architecture / change**
3. **Exact implementation steps**
4. **Smart Approval impact**
5. **Testing steps**
6. **Deployment/activation order**
7. **Known risks / gaps**
8. **Debugging or rollback guidance when relevant**

Do not give conceptual-only answers for implementation requests.

## Smart Approval vs Custom Auto-Approval — Mandatory Option Gate

When the user asks for **Smart Approval**, do not directly recommend, design, or generate:

- `Set custom logic for auto-approvals`
- the `getPreviousRelaRecDetails` Apex wrapper
- `AutoApprovalCustomLogicDecision.cls`
- rule-based auto-approval Apex or evaluator flows

Treat "Smart Approval" as the likely declarative choice, but still confirm it in group B (Pre-Flight row 5) and name the custom Apex-based alternative in one line. Use plain words:

> "Do you want to use Salesforce **Smart Approval** eligibility, or **Set custom logic for auto-approvals** with custom comparison logic? Smart Approval is declarative/framework-driven; custom logic requires an autolaunched evaluator flow and Apex/action support."

Only use Rule-Based Auto-Approvals and related Apex templates if the user explicitly chooses **Set custom logic for auto-approvals** or asks for custom comparison rules. When confirmed, use `templates/AutoApprovalCustomLogicDecision.cls` as the evaluator class template.

---

## Execution Trigger Model — Mandatory Clarification

**Pre-Flight row 3 owns this question; do not ask it twice. Before generating or modifying any approval design, Flow, or implementation, make sure it is answered; if not, ask:**

> "Should this approval be **record-triggered** (fires automatically when a record meets criteria, e.g. Status changes to Needs Review) or **auto-launched / manually invoked** (triggered by a button, Screen Flow, or explicit submit action)?"

Do not ask if the user has already clearly specified the model. Do not assume either model by default.

Use `checklists/flow-trigger-model-checklist.md` to verify all required trigger design decisions are captured.

### Critical Distinction — Approval Orchestration vs Trigger Mechanism

When the user says **record-triggered** or **auto-launched**, first clarify whether they mean the **starter mechanism** or the **main Advanced Approval orchestration Flow**.

For Salesforce Revenue Cloud Advanced Approvals:

- The main approval process should use Salesforce’s Advanced Approval Flow / Approval Process model. **⚠️ In metadata reviews, verify the flow’s `processType` — it may be `ApprovalWorkflow`, `RecordTriggeredFlowApprovalProcess`, or `AutoLaunchedFlow` depending on org/API version. Misclassifying this affects all trigger design decisions. Default to `ApprovalWorkflow` unless the user explicitly confirms a record-triggered approval model.**
- A **Record-Triggered Flow Approval Process** can be valid in Salesforce Advanced Approvals. Distinguish between a record-triggered approval process created by Flow Builder and a separate helper flow that only submits/launches approval.
- A **Record-Triggered Flow** helper may be used as a starter/wrapper to submit or launch approval when a record meets criteria.
- An **Autolaunched Flow** may be used as a reusable utility/background process or explicit submit wrapper.
- Do not convert the main approval orchestration into `RecordTriggeredFlow` or `AutoLaunchedFlow` unless the user is explicitly asking for a non-Advanced-Approval utility flow.

Ask this exact clarification when the trigger model is not clear:

> "Do you want the approval to start automatically from a record change, or should it be launched manually/from another process? The main Advanced Approval orchestration will still be an ApprovalWorkflow unless you want only a helper Flow."

Capture the answer as:

| User choice | Generate / recommend | Do not generate |
|---|---|---|
| Record change starts approval | Record-Triggered Flow Approval Process or record-triggered starter/helper + ApprovalWorkflow, depending on org/API model | Unverified custom approval logic directly inside a generic Record-Triggered Flow |
| Manual/button/API/Screen Flow starts approval | Autolaunched/Screen/Apex starter + ApprovalWorkflow | Record-trigger entry criteria |
| Background auto-approval rule logic | Autolaunched utility Flow + Apex action (`List<Output>` for scalar bindings; `List<List<Output>>` only for collections) | Hardcoded steps or custom collection lists when simple Boolean output is expected |

### If Record-Triggered

Design around:

- `triggerType: RecordAfterSave`, `doesRequireRecordChangedToMeetCriteria: true`
- Entry filter on the status/field change that signals readiness for approval (e.g. `Status = 'Needs Review'`)
- Recursion prevention: entry filter must exclude statuses the approval flow itself writes (e.g. `Approved`, `Rejected`, `In Review`) to avoid re-triggering
- Duplicate submission guard: if a paused interview already exists for the record, do not submit again
- Status-change trigger: approval fires when a specific field change is detected, not on every save

### If Auto-Launched / Manually Invoked

Design around:

- `processType: ApprovalWorkflow` with no record-trigger start (bare start element: locationX/Y + connector only)
- **Stage 1 must gather target object details** before routing or approval decisions. This stage should retrieve/prepare the target record, required approval fields, submitter/context values, and any status/stage fields needed by later approval stages.
- Invocation via button, Screen Flow, Apex, or explicit submit action
- Input variables to receive the record ID and any submission context
- No entry filter needed on the Flow start — caller controls when the flow runs
- Explicit submit/preview UI required for the end user

---

## ApprovalWorkflow Metadata Deployment Contract — MANDATORY

Validated against live deployment failures. Apply ALL of these when generating ApprovalWorkflow flow XML; each one below caused a real deployment rejection or broken rendering when violated.

### 1. Mandatory `firstApprover` variable

`processType: ApprovalWorkflow` flows MUST declare this variable. Deployment fails with: `Because the flow type is Flow Approval Processes, you must define a variable that uses the "firstApprover" API name and the Text data type. The variable must be available for input.`

Always include it.

```xml
<variables>
    <name>firstApprover</name>
    <dataType>String</dataType>
    <isCollection>false</isCollection>
    <isInput>true</isInput>
    <isOutput>false</isOutput>
</variables>
```

Also declare `recordId` (String, isInput). `submitter` and `submissionComments` (String, isInput) are recommended.

Source of this rule: the `firstApprover` requirement comes from live deployment failures and is not stated in the documentation. What the documentation does state: every flow approval process has the variables `recordId`, `submitter` and `submissionComments`, and an autolaunched flow approval process with steps assigned to a Resource assignee type needs at least one input variable holding an active username, a public group API name or a queue API name. Keep `firstApprover` in generated XML regardless.

### 2. User assignees use USERNAME, not User ID

`assigneeType` of `User` requires the **username** (e.g. `user@company.com.sandbox`), NOT the 15/18-character User ID. Passing an ID fails deployment with: `The assigned user <Id> in the assignee field doesn't exist or is inactive. Specify an active user.` — even when the user is active.

```xml
<assignees>
    <assignee>
        <stringValue>user@company.com.sandbox</stringValue>  <!-- username, never 005... Id -->
    </assignee>
    <assigneeType>User</assigneeType>
</assignees>
```

`assigneeType: Group` takes the public group developer name.

### 3. Check org max API version before generating

Before generating flow XML, check the `apiVersion` of existing active approval flows in the org/project and match it (an org rejects a higher value with `The field apiVersion can't be "NN"`). Keep approval workflow flows on the current org API version where possible — background action steps then run synchronously instead of being queued asynchronously.

### 4. No `faultConnector` on stage steps; no orphan stages

See Fault Handling Standard. `FlowStageStep` rejects `<faultConnector>`. Unreachable stages force free-form canvas rendering where stage steps are invisible — the process looks like it has no steps.

### 5. recordLookups field selection in helper flows

`<queriedFields>` requires `<sObjectOutputReference>` (deployment error: `Because the queriedFields field is set, you also need to set the following fields: sObjectOutputReference`). When using `<outputAssignments>` to scalar variables, OMIT `queriedFields` entirely.

### 6. Verify referenced custom fields exist in target org

Before generating a data-retrieval subflow, verify the driving field (e.g. a routing field) exists on the object via FieldDefinition query or describe. Do not trust the field API name given in the requirement — confirm or mark `TODO_VERIFY_IN_ORG` and resolve before deployment.

### 7. `ActionInput__Label` is not a valid step input parameter

`standard_approvals__EvaluateApproval` does NOT accept `ActionInput__Label`. Generating it causes flow **activation failure** (not deployment failure — it passes deploy but blocks activation) with: `Enter a valid name for the ActionInput__Label input parameter.`

Use the step's `<label>` element for display naming only — never an `ActionInput__Label` inputParameter block.

### 8. Stage exit criteria are mandatory on approval stages

Every `orchestratedStage` that contains `stepApproval` steps MUST declare `<exitConditions>` referencing an `IsXxxStageComplete` Boolean formula. Without it, Flow Builder warns "does not have stage exit criteria" and the stage may not advance correctly at runtime.

**Pattern (single stage with multiple serial approval steps):**

```xml
<!-- On the orchestratedStage element -->
<exitConditionLogic>and</exitConditionLogic>
<exitConditions>
    <leftValueReference>IsApprovalsStageComplete</leftValueReference>
    <operator>EqualTo</operator>
    <rightValue><booleanValue>true</booleanValue></rightValue>
</exitConditions>
```

```text
IsApprovalsStageComplete = AND(
  OR(NOT(isLevel1Required), NOT(ISBLANK(Level1Step.Outputs.approvalDecision))),
  OR(NOT(isLevel2Required), NOT(ISBLANK(Level2Step.Outputs.approvalDecision))),
  OR(NOT(isLevel3Required), NOT(ISBLANK(Level3Step.Outputs.approvalDecision)))
)
```

Where `isLevelNRequired` formulas are used ONLY in the exit formula — NOT as step entry conditions.

**Step entry conditions MUST use direct comparisons (variable or step output references), NOT formula references.** Use two explicit `entryConditions` with `entryConditionLogic: and`:

```xml
<!-- Second step in a chain — two direct conditions, no formula reference -->
<entryConditionLogic>and</entryConditionLogic>
<entryConditions>
    <conditionType>EntryCondition</conditionType>
    <leftValueReference>varApprovalLevel</leftValueReference>
    <operator>GreaterThanOrEqualTo</operator>
    <rightValue><numberValue>2.0</numberValue></rightValue>
</entryConditions>
<entryConditions>
    <conditionType>EntryCondition</conditionType>
    <leftValueReference>Level1Step.Outputs.approvalDecision</leftValueReference>
    <operator>EqualTo</operator>
    <rightValue><stringValue>Approve</stringValue></rightValue>
</entryConditions>
```

`isLevel2Required` and `isLevel3Required` formulas exist only to power `IsApprovalsStageComplete` — they are NOT referenced in step `<entryConditions>`.

**Null-safe routing numbers:** a blank routing number (a record with no level but another independent branch's flag set) makes `level < 1` evaluate to null instead of true, and the stage never exits. Add a formula `ApprovalLevelSafe = IF(ISBLANK(level), 0, level)` and use it inside `isLevelNRequired` and `IsApprovalsStageComplete`; keep the raw step-output reference in step `<entryConditions>`.

**Why rejection early exit works:** When Level 1 rejects, `isLevel2Required` becomes false → `OR(NOT(false), ...)` = true → `IsApprovalsStageComplete` = true → stage exits immediately without waiting for Level 2/3 steps.

**Serial vs parallel inside one stage:** steps whose entry conditions are met start together. Serial order comes only from a step's entry condition referencing the previous step's `approvalDecision`. Use `= Approve` to continue only after approval; use `IsNull = false` (boolean `false`) to continue after any decision, including a rejection. A step with no dependency on another step runs in parallel with it.

**Anti-pattern:** A flow that omits `<exitConditions>` on approval stages is invalid even if it deploys — it will fail to advance correctly at runtime. Do not treat any flow lacking exit criteria as a valid model, regardless of its source.

### 9. Record input on `standard_approvals__EvaluateApproval` steps

Each `stepApproval` step using `actionName` `standard_approvals__EvaluateApproval` MUST pass the record via `ActionInput__RecordId` (value: `elementReference` to the `recordId` flow variable). Without it, deployment fails with: `field integrity exception: unknown (A context record is required for interactive steps.)`.

Do NOT pass a plain `recordId` input parameter to this action. Deployment fails with: `Enter a valid name for the recordId input parameter.` (`recordId` is valid only when the step calls your own screen flow as the approval action.)

Minimum valid input set for a `standard_approvals__EvaluateApproval` step:

```xml
<inputParameters>
    <name>ActionInput__RecordId</name>
    <value><elementReference>recordId</elementReference></value>
</inputParameters>
<inputParameters>
    <name>ActionInput__ApprovalChainName</name>
    <value><stringValue>Business_Domain_Approval_Chain</stringValue></value>
</inputParameters>
<inputParameters>
    <name>ActionInput__CanUseSmartApproval</name>
    <value><stringValue>true</stringValue></value>
</inputParameters>
```

A complete worked flow is in `examples/serial-tiered-approvalworkflow-example.md`.

### 10. Helper metadata gotchas (validated on deploy)

- **Queues** (only when a step is assigned to a queue): `Queue` metadata uses the singular element `<queueSobject><sobjectType>&lt;ApprovedObject&gt;</sobjectType></queueSobject>`. The plural `queueSobjects` fails with `Element ... queueSobjects invalid at this location in type Queue`. A queue used as an approval assignee must already exist before the flow is deployed, and should list the approved object. Public groups and users must likewise exist and be active. In Queue metadata `<name>` is the label (write it with spaces); the developer name comes from the file name (`Manager_Queue.queue-meta.xml`), and steps reference the developer name. Template: `templates/submit-chain-templates.md`.
- **Public groups** (only when a step is assigned to a group): `Group` metadata takes only `<name>` (the label); adding `doesIncludeBossSubordinates` fails to parse. The developer name comes from the file name, and the group must exist before the ApprovalWorkflow deploys. Template: `templates/submit-chain-templates.md`.
- **Get Records in helper flows:** `<assignNullValuesIfNoRecordFound>` is rejected inside `recordLookups` (`invalid at this location in type FlowRecordLookup`). Omit it.
- **Field-level security:** a custom field deployed by metadata has NO field-level security for any profile. Apex and users cannot see it (`Field does not exist: <Field> on <Object>`) until a permission set grants it. If the approval design adds a field (e.g. a routing field), also deploy a permission set with `fieldPermissions` and assign it to the users/test users.

- **Deploy order and Apex tests** (applies only if the user chose to deploy and the build includes a starter Apex class with tests): deploy assignee records (e.g. queues), starter Apex with no tests (`NoTestRun`), helper flows plus the ApprovalWorkflow, then run the Apex tests only if the user chose to test. The starter launches the ApprovalWorkflow at runtime, and the ApprovalWorkflow needs its assignees, so a single combined deploy with `RunSpecifiedTests` fails (`Invalid type: <FlowName>` in the tests, or `The assigned queue "<Queue>" in the assignee field doesn't exist`).

### 11. Canvas mode — set `AUTO_LAYOUT_CANVAS` and verify in Flow Builder

Always declare auto-layout at the flow top level (next to `<processType>`), and keep every `locationX`/`locationY` at `0`:

```xml
<processMetadataValues>
    <name>CanvasMode</name>
    <value><stringValue>AUTO_LAYOUT_CANVAS</stringValue></value>
</processMetadataValues>
```

Without it the flow can open in **free-form canvas**, where stage steps are not drawn: stages appear as bare nodes and the process looks like it has no steps, even though the metadata deploys and runs correctly. This is separate from the orphan-stage cause in the Fault Handling Standard. Treat it as a mandatory check: a runtime test alone does not catch it.

**Post-deploy check:** open the flow in Flow Builder and confirm the approval steps show inside each stage. If they do not, check `CanvasMode` first, then orphan stages.

---

## Architecture Decision Framework

Before designing approval changes, reason through these steps:

### Step 1 — Identify approval type

Classify the business reason (examples only; any business reason or object applies):

- Discount approval
- Margin approval
- Approval-sensitive field approval
- Legal terms approval
- Product exception approval
- Region/country approval
- Customer/account risk approval
- Contract/commercial approval
- Compliance approval

### Step 2 — Identify routing pattern

Choose one:

- Static public group
- Named user
- Level 1 Approver hierarchy
- Dynamic user lookup
- Approval matrix object
- Territory/region-based routing
- Product-family approver
- Parallel chain
- Serial chain

### Step 3 — Identify execution model (trigger)

If not already clarified, ask now — see **Execution Trigger Model — Mandatory Clarification** above.

### Step 4 — Identify approval chain execution pattern

Choose:

- Serial approval
- Parallel approval
- Hybrid serial + parallel
- Any-one approver in group
- All approvers required
- Conditional chain

See `references/generic-approval-stage-and-exit-patterns.md` for reusable stage and exit-condition patterns for each execution model above.

### Step 5 — Determine Smart Approval eligibility

Smart Approval is appropriate only if unchanged approval-relevant conditions can safely skip reapproval.

### Step 6 — Determine lock/edit strategy

Decide whether `shouldLock` and `canAssigneeEdit` should be true or false per step.

### Step 7 — Determine observability

Define logs, SOQL checks, Flow interview monitoring, and post-deployment validation.

### Step 8 — Determine deployment impact

List metadata changes, dependencies, activation order, and sandbox validation.

Use `checklists/enterprise-approval-design-checklist.md` to validate all design decisions before implementation.

---

## Enterprise Approval Standards

Read `references/enterprise-approval-standards.md` — naming, structure, routing, and governance standards for enterprise approval implementations.

## Generic Approval Design Patterns

Read `references/generic-approval-design-patterns.md` — reusable approval chain, routing, and stage design patterns.

## Smart Approval Standard

Smart Approval requires both:

1. Step-level enablement:
   ```text
   ActionInput__CanUseSmartApproval = "true"   (string value, not boolean)
   ActionInput__ApprovalChainName   = "<chain-name>"
   ```
   Also required on each `standard_approvals__EvaluateApproval` step: `ActionInput__RecordId` (see Deployment Contract rule 9). **`ActionInput__Label` is NOT a valid input parameter** — flow activation fails with "Enter a valid name for the ActionInput__Label input parameter." Never generate it. Use the step's `<label>` element for display naming only. (Canonical rule: ApprovalWorkflow Metadata Deployment Contract item 7.)

2. Advanced Approvals turned on for the org (Setup → Approval Settings → **Use Advanced Approvals**; see `references/approvals-settings-base-configuration.md`). There is no separate Smart-Approval-only org switch in the documentation. Per approval step, Smart Approval is turned on by selecting **Use Smart Approval** in the step's properties in Flow Builder (stored as `ActionInput__CanUseSmartApproval`). `ActionInput__ApprovalChainName` is a free-form string label — no corresponding record or UI object needs to be created. Pre-Flight row 17 derives the names from the design: steps that form one chain share a name and each other kind of approval gets its own (one name only when there is one kind). Steps in one chain name share reuse history, so give two steps the same name only when they should be treated as one chain. Verify the grouping by resubmitting an unchanged record after a rejection.

   The step also has a **Smart Approval Skip Conditions** field: a comma-separated list of start-condition numbers (1-based, in the order of the step's "Requirements to Start Step" list) to leave out of the comparison; an invalid value or a resource means nothing is skipped. The XML input name for it is `TODO_VERIFY_IN_ORG` — read it from a step saved in Flow Builder before generating it.

Smart Approval can skip repeated work items only when framework eligibility is met. Do not say it “always skips” or “always auto-approves.” Documented eligibility limits (Help: "Smart Approvals" and "Smart Approval Limitations"):

- A step that starts "when the specified requirements are met" can use up to 30 conditions; conditions on Apex and Record data types are not eligible.
- A step that starts "when the specified evaluation flow returns True" is not eligible, and using an evaluation flow as an entry or exit condition on any step marks the whole flow ineligible.
- If a decision element sits before the stage that contains the step, the Smart Approval evaluation fails.
- Resubmission must use the same flow definition version as the original submission; if the active version changes, Smart Approval is not considered.

### Smart Approval Decision Matrix

Quick scenario lookup below. For the full **eligibility ruleset** (documented Salesforce
limitations: 30-condition cap, NOT-operator ineligibility, flow-version-change rule,
Rejected/Recalled trigger requirement, work-item-reassignment), the materiality-hash
model, and the test procedure, read `references/smart-approval-decision-matrix.md`.

| Scenario | Expected guidance |
|---|---|
| Non-material field changed | May skip if framework/config allows. Verify. |
| Value an approval depends on moved toward a stricter threshold | Usually reapproval required. |
| Value moved toward a looser threshold | May skip or require based on rule/condition config. |
| Field that gates a specialist step changed | That specialist step likely requires reapproval. |
| Same approver and the step's start conditions still met on resubmission | Smart Approval may apply. |
| Approver removed from group | Smart Approval may not match. |
| Use Smart Approval off on the step, or Advanced Approvals off for the org | Smart Approval will not apply. |
| New approval step added | No prior approval history; manual approval likely required. |

---

## Fault Handling Standard

⛔ **CRITICAL METADATA CONSTRAINT:** `FlowStageStep` elements (the `stageSteps` inside `orchestratedStages` of an ApprovalWorkflow flow) do **NOT** support `<faultConnector>`. The Metadata API rejects fault connectors on `stepApproval` and `stepBackground` stage steps. Never generate them there.

**Where fault handling actually goes:** inside the autolaunched utility subflow that the `stepBackground` calls. Regular flow elements (Get Records, Update Records, Action calls, Subflow calls) in an AutoLaunchedFlow fully support `<faultConnector>`. Put the fault path there.

⛔ **NEVER create an unreachable stage.** Do not add a "Fault Handler" stage (or any stage) to an ApprovalWorkflow that has no inbound connector. An orphaned element forces Flow Builder to open the flow in **free-form canvas** instead of auto-layout. In free-form canvas, stage steps are NOT rendered on the canvas — the approval process appears to have no steps at all and looks broken, even though the metadata is correct. Every stage and decision must be reachable from Start via connectors.

Fault paths must be **org-neutral** — never hardcode custom logging objects such as `Approval_Action_Log__c` because that object may not exist in the target org.

Org-neutral recommended pattern (inside the utility subflow, NOT in the ApprovalWorkflow):

```text
AutoLaunchedFlow (called by stepBackground)
  Get Records / Update Records / Action element
    ↓ faultConnector (supported here)
  Update source record status = Approval Error
    ↓
  Store {!$Flow.FaultMessage} in a text variable
    ↓
  Choose notification mechanism available in the org:
    Option A: Send email alert to submitter/admin
    Option B: Create a platform event (decouple logging from the orchestration)
    Option C: If the org has a custom logging object, create a record with the error
              — do NOT assume Approval_Action_Log__c or any specific object exists
              — ask the user which object to use
```

When generating fault path steps, Claude must:
- Put fault connectors ONLY on regular flow elements inside autolaunched subflows — never on ApprovalWorkflow stage steps
- Use the minimal org-neutral pattern above by default; ask about a logging mechanism (custom object, platform event, email alert) only if the user wants logging beyond it
- If the org has no logging object, suggest creating `Approval_Action_Log__c` with recommended fields (see Observability Standard)
- Never insert a DML Create step for any custom logging object without first confirming it exists or the user has agreed to create it
- Default to a safe minimal pattern when uncertain: update source status, store fault message in a variable, send email/custom notification

Lack of explicit fault connectors in utility subflows is a common improvement area; verify the target implementation.

---

## Observability Standard

Troubleshoot in layers:

1. Source record values
2. ApprovalSubmission
3. ApprovalWorkItem
4. FlowInterview / paused interviews
5. Debug logs
6. Public groups and group members
7. Approval Settings (Use Advanced Approvals) and the step's Use Smart Approval setting; no per-chain record exists — chain name is a free-form string in flow XML
8. Flow XML metadata
9. Lightning page components and submit action

For SOQL queries and the full diagnostic sequence, read `references/observability-debug-framework.md`. For enterprise troubleshooting patterns and escalation steps, read `references/troubleshooting-enterprise.md`.

---

## Reasoning Instructions

When asked to design or modify approvals:

**Prerequisites — run the Pre-Flight Gate and Required Process Skeleton above first; the two items below are its rows 3 and 5:**
- **Execution trigger model** — record-triggered or auto-launched. Block design until confirmed. (See Execution Trigger Model above.)
- **Smart Approval vs. custom auto-approval** — "Smart Approval" means the declarative model; ask which model only if the user mentions custom or rule-based comparison. (See Smart Approval vs Custom Auto-Approval above.)

1. Identify business requirement.
2. Determine approval dimensions.
3. Choose approval routing model.
4. Decide serial/parallel/hybrid execution.
5. Decide Smart Approval applicability, or custom auto-approval only if explicitly selected.
6. Define data source/subflow outputs.
7. For auto-launched/manually invoked approval processes, define Stage 1 target object detail retrieval before approval routing.
8. Define approval step entry conditions.
9. Define completion formulas.
10. Define rejection behavior.
11. Define status update logic.
12. Define fault handling.
13. Define testing.
14. Define deployment order.

Always preserve existing production implementation unless the user explicitly asks to replace it.

---

## Rule-Based Auto-Approvals Standard

Read `references/rule-based-auto-approvals-standard.md` — rule-based auto-approval configuration, custom logic, and decision standards (load this file for standards and evaluation logic). Also load `references/rule-based-auto-approvals.md` — foundational rule-based approval guide covering rule field mappings, rule types, and condition setup (distinct from the standards file above). Load both when covering rule-based auto-approvals end-to-end.

## Per-Step Custom Auto-Approve Pattern (Apex Evaluator)

Read `references/per-step-custom-auto-approve.md` — pattern for per-step auto-approval using an Apex evaluator class + `ApprovalPreviousRelatedRecordDetails` (Revenue Cloud built-in action). For the Apex class template, read `templates/ApprovalPreviousRelatedRecordDetails.cls`. Use when:
- Resubmissions should auto-approve steps whose prior decision was `Approved`
- Resubmissions should NOT auto-approve steps whose prior decision was `Rejected`
- Approval level has not increased between submissions (Apex `currentLevel <= previousLevel` guard)

Key design principles:
- **4-stage flow:** GetDetails → EvaluateAutoApproval → Approvals → Finalize
- **Apex queries by step label** (`FlowOrchestrationWorkItem.Label`) — not positional loop — for per-step Boolean outputs
- **Step entry conditions stay standard** (level check + predecessor decision only) — never put auto-approve booleans in step conditions; doing so with complex logic causes Flow Builder validation warnings
- **Auto-approve booleans used only in formulas** (`IsApprovalsStageComplete`, `isXRequired`, `finalStatus`)
- Never use a single shared `canAutoApprove` boolean — it cannot distinguish per-step prior outcomes

## Critical Guardrails

Never:

- Recommend Classic Approval Process for new Revenue Cloud Advanced Approval orchestration.
- Conflate `ApprovalWorkflow` with record-triggered Flow.
- Suggest activating draft flows in production without review.
- Cite dead/unwired formulas as active logic.
- Omit testing and deployment guidance from the written plan (the user may still choose to generate only; give the guidance, do not execute it unless Pre-Flight row 9 says so).
- Omit any approval step that can reject from the overall rejection formula.
- Hard-code users when a public group, matrix, or dynamic lookup is better.
- Assume Smart Approval applies without Use Smart Approval selected on the step and Advanced Approvals turned on for the org.
- Instruct users to "create a chain" in the UI as a deployment step — `ActionInput__ApprovalChainName` is a free-form string label used for Smart Approval history grouping, not a reference to any record or metadata type. No creation step needed.
- Derive the chain name from the flow API name — choose it as a business-domain label, independent of the flow name, so Smart Approval history survives flow renames and version changes (it may match the naming convention text, but is never tied to the flow after creation).
- Recommend direct status updates as a substitute for real approval submission.

For execution-trigger guardrails (record-triggered vs. auto-launched, Stage 1 gathering, recursion prevention), see **Execution Trigger Model** above. For Smart Approval option gate guardrails, see **Smart Approval vs Custom Auto-Approval** above. For metadata XML deployment guardrails (`ActionInput__Label`, `<exitConditions>`, formula references in entry conditions, `faultConnector` on stage steps), see **ApprovalWorkflow Metadata Deployment Contract** and **Fault Handling Standard** above. For per-step auto-approve guardrails (`canAutoApprove` boolean, evaluator stage design, GetDetails subflow scope), see **Per-Step Custom Auto-Approve Pattern** above. For fault-path and audit logging anti-patterns, see **Fault-Logging Anti-patterns** below.

Always:

- State assumptions.
- Prefer declarative Flow/AA configuration.
- Include how to test (describe it; run it only if the user chose to test).
- Include deployment order (run it only if the user chose to deploy).
- Include rollback/debug strategy for risky changes.
- Convert target-org examples into reusable patterns before applying them.
- Add `<exitConditions>` on every approval stage referencing an `IsXxxStageComplete` Boolean formula.
- Use direct variable/step-output comparisons in step entry conditions — never formula references.
- Set `CanvasMode` = `AUTO_LAYOUT_CANVAS` in ApprovalWorkflow XML and confirm in Flow Builder that steps render inside stages (Deployment Contract rule 11).


---

## Approver Record Access & Sharing

When users ask to create a new approval workflow/process, step, chain, approver
routing, or dynamic approver logic, the agent must evaluate whether approvers can
access the underlying business records beyond approval assignment.

### Approval Access Rule

Approval assignment does **not** guarantee access to the source or related records.
Approvers must have the required read/edit access to perform approval actions.

The agent must evaluate, state in the plan, and ask only per Pre-Flight row 8:

- Do approvers already have access to the source object?
- Do approvers need access to related objects?
- Should record sharing be implemented? Is dynamic sharing required?

If access is unclear, recommend validating: OWD, role hierarchy, sharing rules,
teams/manual sharing, Apex managed sharing, trigger-based sharing.

### Mandatory Clarification

Pre-Flight row 8 owns this and it is always asked in group A, with the object's org-wide default (read-only lookup) shown in the question. Never assume access is covered without that lookup:

```text
Do you want me to implement trigger-based or Apex-managed sharing so approvers can access the source record and related records during approval?
```

### Default Behavior

Do not automatically generate trigger-based sharing unless the user confirms it is required.

If the user says yes, generate:

- trigger or record-triggered sharing entry point — default to the official temporary-access pattern (trigger on `ApprovalWorkItem` using `RelatedRecordId` + `AssignedToId`); use a source-object trigger only when sharing must exist before work items are created
- bulk-safe sharing handler
- duplicate-share prevention
- revoke/cleanup on terminal work-item status (temporary access) — required for the official pattern, optional otherwise
- Apex sharing reason RowCause for custom related objects (standard share objects only accept `Manual`)
- tests
- deployment steps

If the user says no, still include a note that approvers must have access through OWD, role hierarchy, sharing rules, teams, manual sharing, or permission model.

### Fault-Logging Anti-patterns

Claude must avoid:

- Inserting a DML Create step for `Approval_Action_Log__c` in a fault path without first confirming the object exists in the target org — ask the user, and if it doesn't exist, suggest creating it with the recommended fields from the Observability Standard.
- Assuming any custom logging object exists without asking; always confirm before writing Create Records steps.
- Omitting fault paths from the autolaunched utility subflows that stage steps call.
- Providing happy-path-only orchestration designs without error handling.

> Metadata-XML anti-patterns (faultConnector on stage steps, orphan stages,
> hardcoded User IDs, missing `firstApprover`) are canonical in the
> **ApprovalWorkflow Metadata Deployment Contract** above — see that section.

Use `checklists/approval-access-checklist.md` to verify approver access is addressed for each approval design.

---

## Trigger Sharing References

Use these files when the user confirms trigger/Apex sharing is needed:

```text
references/trigger-based-approval-record-sharing.md
templates/ApprovalWorkItemSharingTrigger.trigger      (official temporary-access pattern — default)
templates/ApprovalWorkItemSharingService.cls
templates/ApprovalRecordSharingTrigger.trigger   (source-object pattern)
templates/ApprovalRecordSharingHandler.cls
templates/ApprovalRecordSharingService.cls
examples/quote-approval-sharing-example.md
checklists/trigger-sharing-implementation-checklist.md
```

## Reference index

Additional bundled files — load by topic when inline section pointers do not cover the question:

**references/** (not linked inline above): `references/approver-experience-and-email-options.md`, `references/serial-chain-with-independent-approvals.md`, `references/runtime-testing-approvals.md`, `references/advanced-approval-architecture.md`, `references/advanced-approvals-considerations.md`, `references/advanced-approvals-limitations.md`, `references/approval-decision-framework.md`, `references/approval-record-access.md`, `references/approval-reminders.md`, `references/approvals-page-customization.md`, `references/approvals-settings-base-configuration.md`, `references/approvals-slack-integration.md`, `references/deployment-standards.md`, `references/email-templates-advanced-approvals.md`, `references/enterprise-implementation-patterns.md`, `references/fault-handling-standards.md`, `references/flow-orchestration-fundamentals.md`, `references/generic-approval-stage-and-exit-patterns.md`, `references/observability-debug-framework.md`, `references/preview-approvals-mechanics.md`, `references/rule-based-auto-approvals.md`, `references/smart-approval-decision-matrix.md`, `references/troubleshooting-enterprise.md`

**templates/**: `templates/field-templates.md` (missing routing fields and field-access permission set), `templates/helper-flow-templates.md` (complete gather subflow and status subflow), `templates/submit-chain-templates.md` (quick action, screen flow, comments screen, queue, public group), `templates/ApprovalStarter.cls`, `templates/GenericApprovalStarter.cls`, `templates/ApprovalStarterTest.cls`, `templates/ApprovalPreviousRelatedRecordDetails.cls` (per-step auto-approve Apex), `templates/AutoApprovalCustomLogicDecision.cls` (custom evaluator — use only when user chooses custom logic), `templates/rule-based-auto-approval-flow-template.md`, `templates/implementation-templates.md`, `templates/ApprovalWorkItemSharingTrigger.trigger`, `templates/ApprovalWorkItemSharingService.cls`, `templates/ApprovalRecordSharingTrigger.trigger`, `templates/ApprovalRecordSharingHandler.cls`, `templates/ApprovalRecordSharingService.cls`

**examples/**: `examples/add-cfo-tier.md`, `examples/fix-payment-terms-rejection.md`, `examples/payment-terms-rule-based-auto-approval.md`, `examples/generic-stage-exit-criteria-example.md`, `examples/multi-stage-sequential-approvalworkflow-example.md`, `examples/consolidated-role-approval-example.md`, `examples/quote-approval-sharing-example.md`

**checklists/**: `checklists/enterprise-approval-design-checklist.md`, `checklists/flow-trigger-model-checklist.md`, `checklists/approval-access-checklist.md`, `checklists/trigger-sharing-implementation-checklist.md`

**prompts/** (human operator reference): `prompts/approval-record-sharing-prompt.md`, `prompts/claude-prompts.md`
