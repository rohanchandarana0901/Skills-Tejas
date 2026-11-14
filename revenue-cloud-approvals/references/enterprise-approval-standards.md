# Enterprise Approval Standards

## Enterprise Approval Standards

### Prefer Flow-Based Advanced Approvals

Use `processType: ApprovalWorkflow` for orchestration. Do not replace orchestration logic with record-triggered flows.

Use record-triggered flows only to initiate/submit approval or update auxiliary data, not to model approval steps.

### Flow Orchestration Fundamentals

Advanced Approvals is powered by Flow Orchestration. When designing approval workflows, understand:
- Orchestration pause/resume mechanics
- Standard Flow/Apex governor limits (no separate published Advanced Approvals caps)
- Fault handling requirements

Load:
```text
references/flow-orchestration-fundamentals.md
```

### Approval Reminder Pattern

When the user asks for approval reminders, reminder emails, or escalation-style nudges for pending approval work items, load:

```text
references/approval-reminders.md
```

Use this pattern for reminder notification helpers only. Do not use it to replace the main Advanced Approval orchestration.

### Slack Integration for Approvals

When the user asks for Slack approval notifications, in-Slack approval decisions, or integration with Approvals in Slack, load:

```text
references/approvals-slack-integration.md
```

Covers setup, Slack approver experience, sync behavior (not real-time from Salesforce/email to Slack), and troubleshooting.

### Custom Email Templates for Approvals

When the user needs custom notification emails for approval steps, load:

```text
references/email-templates-advanced-approvals.md
```

Covers template creation, merge fields, patterns, and best practices.

### Approval Page Customization

When the user wants to customize approval pages with Lightning components, custom actions, or related lists, load:

```text
references/approvals-page-customization.md
```

Covers source record pages, approval work item pages, and component patterns.

### Approvals Settings Base Configuration

When the user is implementing Advanced Approvals for the first time, load:

```text
references/approvals-settings-base-configuration.md
```

Mandatory setup: approval queue, notifications, Smart Approval, routing, SLA, security, and monitoring.

### Advanced Approvals Limitations & Known Constraints

When the user asks about approval limits, known constraints, or troubleshooting system boundary issues, load:

```text
references/advanced-approvals-limitations.md
```

Covers design constraints and workaround patterns. For official documented limitations and behaviors, load references/advanced-approvals-considerations.md.

### Preview Approvals Mechanics

When the user wants to implement Preview Approvals (simulation without work-item creation), load:

```text
references/preview-approvals-mechanics.md
```

Covers preview execution, routing simulation, best practices, and comparison with Smart Approval.

### Prefer Declarative First

Prefer:

- Flow orchestration
- Advanced Approvals chains
- Public groups
- Matrix objects/custom metadata
- Invocable actions
- Autolaunched subflows

Use Apex only when:

- dynamic logic cannot be modeled declaratively
- complex matrix evaluation requires code
- external integration is required
- bulk/idempotency logic is beyond Flow limits

### Separate Trigger Logic from Approval Chain Logic

Do not mix “does this record need approval?” with “who approves it?” too tightly.

Good pattern:

```text
Data Subflow
  ↓
Outputs approval facts
  ↓
Requires Approval decision
  ↓
Stage steps evaluate routing conditions
```

### Use Formula-Based Stage Completion

For each independent approval type, create one Boolean formula:

```text
Is[ApprovalType]Completed = OR(not_required_condition, required_step_completed)
```

Stage exit should be:

```text
(all approval-type completion formulas are true) OR rejected
```

---

## ActionInput__ApprovalChainName — Naming Standard

`ActionInput__ApprovalChainName` is a free-form string passed to each `stepApproval` in a Flow Approval Process. The framework uses it to group steps for Smart Approval history matching during resubmission. **No record, metadata type, or UI object needs to be created.**

### Naming pattern: `{Object}_{ApprovalDomain}`

Reflect the **business approval domain**, not the flow name. Smart Approval history is keyed by chain name — if the flow is renamed or versioned, prior approval history remains valid as long as the chain name is unchanged.

| Use Case | Recommended Chain Name |
|---|---|
| Hierarchical / manager / discount approval | `Quote_HierarchyApproval` |
| Specialist / product exception approval | `Quote_SpecialistApproval` |
| Legal terms approval | `Quote_LegalApproval` |
| Compliance / regulatory approval | `Quote_ComplianceApproval` |
| Region / territory approval | `Quote_RegionApproval` |
| Parallel multi-domain (same flow) | each domain gets its own chain name |

### Rules

- Use the same chain name across all steps that share the same logical approval domain
- Use the same chain name across flow versions — Smart Approval history carries forward on resubmission
- Different business domains in the same flow must use different chain names
- Never use the flow API name as the chain name — coupling naming to implementation breaks Smart Approval history on flow rename

---
