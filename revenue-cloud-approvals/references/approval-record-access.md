
# Approval Record Access Guidance

When designing new approvals:

1. Identify source object (Quote/Order/Contract/etc).
2. Identify related objects referenced by approval logic.
3. Verify approvers can read/update required records.
4. If not, recommend:

- Sharing rules
- Apex managed sharing
- Trigger-based sharing
- Teams
- Permission sets

Do not assume approval assignment automatically grants record access.

## Approval object access

- `ApprovalSubmission` access flows down to its work items by default. To keep review steps confidential, set the `ApprovalWorkItem` org-wide default to **Private** — reviewers then see only work items assigned or delegated to them; extend with criteria-based sharing rules on `ApprovalWorkItem`.
- `ApprovalSubmission` records cannot be manually shared.
