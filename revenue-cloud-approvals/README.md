# Revenue Cloud Approvals

Reusable Salesforce Revenue Cloud Advanced Approvals skill.

Use this skill for Flow-based Advanced Approvals, Smart Approvals, approval preview/submission, approval routing, approval chains, rule-based auto-approvals, record access for approvers, troubleshooting, testing, and deployment patterns.

## Scope

This skill is intentionally generic. It must not rely on customer-specific flow names, field names, public groups, users, org URLs, or Salesforce record IDs.

## Main File

```text
SKILL.md
```

## Key References

```text
references/advanced-approval-architecture.md
references/generic-approval-stage-and-exit-patterns.md
references/approval-decision-framework.md
references/smart-approval-decision-matrix.md
references/rule-based-auto-approvals.md
references/approval-reminders.md
references/trigger-based-approval-record-sharing.md
references/enterprise-implementation-patterns.md
references/troubleshooting-enterprise.md
references/deployment-standards.md
references/serial-chain-with-independent-approvals.md
references/runtime-testing-approvals.md
```

## Generic Approval Patterns Added

- Approval stage field design: Formula vs Picklist vs Text
- Stage exit criteria formulas with placeholders
- Approval matrix examples using generic thresholds and roles
- Parallel approval chain pattern
- Serial approval chain pattern
- Approval reminder pattern for pending approval work items
- Record sharing/access pattern for approvers
- Rule-based auto-approval pattern for unchanged approval-sensitive fields

## Generic Content Rules

- Do not hardcode customer names, org names, local file paths, emails, org URLs, or Salesforce record IDs.
- Replace implementation-specific metadata with placeholders such as `<approval-flow-api-name>`, `<approval-status-field>`, `<approval-stage-field>`, `<approval-chain-name>`, `<approver-group>`, `<threshold>`, and `<business-record-id>`.
- Convert any target-org example into a reusable pattern before returning guidance.
