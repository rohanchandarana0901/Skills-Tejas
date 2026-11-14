# Trigger-Based Approval Record Sharing

Source: https://help.salesforce.com/s/articleView?id=ind.approvals_share_records_using_triggers.htm&type=5 — "Share Temporary Access to Records in Advanced Approvals" (verified 2026-06-12)

## Purpose

Use this pattern when approvers do not automatically have access to the source approval record or related records.

Approval assignment alone does not guarantee record access. If the object sharing model is private or related objects are restricted, approvers may be unable to view or act on approval requests.

## Claude Behavior

When designing a new approval, Claude must ask:

```text
Do you want me to implement trigger-based or Apex-managed sharing so approvers can access the source record and related records during approval?
```

Do not generate trigger sharing automatically unless the user confirms it is needed.

## When to Recommend Trigger/Apex Sharing

Recommend this when:

- OWD is Private or Restricted
- approvers are outside the owner role hierarchy
- approvers are dynamically assigned
- approvers need access to related Quote/Order/Contract/Line records
- approval work items are visible but source record cannot be opened
- sharing rules cannot express the dynamic approver logic
- public group membership changes frequently
- quote approval uses custom approver matrix

## When Not Required

Trigger-based sharing may not be required when:

- OWD is Public Read/Write
- role hierarchy already grants access
- sharing rules cover all approvers
- account/opportunity/quote teams grant access
- approvers only need approval task visibility and not source record detail

## Two Trigger Placements — Choose One

| Placement | Trigger object | Approver source | When to prefer |
|---|---|---|---|
| **ApprovalWorkItem (official temporary-access pattern)** | `ApprovalWorkItem` | `AssignedToId` field — no custom resolution needed | Default. Approver is known at work-item creation; works for dynamic approvers; `RelatedRecordId` makes it source-object agnostic |
| Source object (e.g. Quote) | Quote/Order/custom object | Custom resolver (approval matrix, lookup fields, groups) | Sharing must exist before submission, or approvers are not yet represented as work items |

## Official Pattern — Temporary Access via ApprovalWorkItem Triggers

This is the pattern in the Salesforce help article "Share Temporary Access to Records in Advanced Approvals". Access is **temporary**: granted when the approval work item is assigned, withdrawn when the approval action completes.

```text
ApprovalWorkItem created/assigned (after insert / after update)
  ↓
Read RelatedRecordId + AssignedToId from the work item
  ↓
Resolve share object for the related record's SObjectType
  (standard: e.g. QuoteShare; custom: <Name>__Share)
  ↓
Insert share row (ParentId = RelatedRecordId, UserOrGroupId = AssignedToId)
  ↓
Approver acts on approval request
  ↓
ApprovalWorkItem reaches a terminal status (after update)
  ↓
Delete the share row created for that approver → access withdrawn
```

Key fields on `ApprovalWorkItem`:

| Field | Use |
|---|---|
| `RelatedRecordId` | ParentId of the share row — the record the approver must access |
| `AssignedToId` | UserOrGroupId of the share row — the approver |
| Status | Drives grant vs revoke. `ApprovalWorkItem.Status`: `Assigned` = grant; `Approved`, `Rejected`, `Recalled`, `Canceled`, `Withdrawn`, `Errored` = revoke |

Templates:

```text
templates/ApprovalWorkItemSharingTrigger.trigger
templates/ApprovalWorkItemSharingService.cls
```

### Dynamic Share Object Resolution (custom objects)

For custom related records, build the share object name dynamically:

```apex
SObjectType relatedRecordType = relatedRecordId.getSObjectType();
if (relatedRecordType.getDescribe().isCustom()) {
    String shareName = relatedRecordType.getDescribe().getName().removeEnd('__c') + '__Share';
    // Schema.getGlobalDescribe().containsKey(shareName) == false
    // means OWD is Public Read/Write — no share object exists, no share needed
}
```

If the `__Share` type is absent from the global describe, the custom object's OWD is Public Read/Write and no sharing is required.

### Apex Sharing Reason (custom objects — recommended)

For custom related objects, create an **Apex sharing reason** (Setup → object → Apex Sharing Reasons, or `sharingReasons` in the object metadata) and use it as the RowCause, e.g.:

```text
RowCause = 'AdvancedApprovalTriggerShareReason__c'
```

Why:

- scopes revoke queries/deletes to rows created by this use case only — never touches manual or rule-based shares
- distinguishes approval-time shares from `Manual` rows, which Salesforce can delete on owner change or sharing recalculation
- standard objects (QuoteShare etc.) do **not** support Apex sharing reasons — use `RowCause = 'Manual'` and filter revoke deletes by ParentId + UserOrGroupId instead

Revoke query shape (custom object with sharing reason):

```apex
Database.query('SELECT Id FROM ' + shareName +
    ' WHERE RowCause = \'AdvancedApprovalTriggerShareReason__c\'' +
    ' AND ParentId = :relatedRecordId AND UserOrGroupId = :assignedToId');
```

### Note on the Help Article Sample

The article's sample trigger (`AWIUpdate on ApprovalWorkItem`) is illustrative but incomplete: it queries the share rows and never deletes them, requeries `Trigger.new` unnecessarily, and performs SOQL inside the loop (not bulk-safe). Use `templates/ApprovalWorkItemSharingService.cls` for a corrected, bulk-safe implementation.

## Standard Design (source-object placement)

```text
Approval trigger condition
  ↓
Identify source record
  ↓
Identify approver user/group ids
  ↓
Create <Object>Share records
  ↓
Avoid duplicates
  ↓
Remove shares after approval completes/recalls/cancels (temporary access)
```

## Key Design Decisions

| Decision | Recommendation |
|---|---|
| Source object | Quote, Order, Contract, or custom source object |
| Share target | User or public group |
| Access level | Read or Edit based on approval action needs |
| Trigger placement | ApprovalWorkItem (official, default) vs source object |
| RowCause | Custom Apex sharing reason for custom objects (e.g. `AdvancedApprovalTriggerShareReason__c`); `Manual` for standard objects |
| Cleanup | Required for temporary access (official pattern); otherwise based on compliance/security requirement |
| Related records | Share separately if approver must open child/related records |

## Important Salesforce Notes

- Standard objects use standard share objects such as `QuoteShare` where available.
- Custom objects use `<CustomObject>__Share`.
- Some objects may not support Apex managed sharing in the same way.
- Manual share rows can be recalculated or removed in some ownership/sharing changes.
- Always test as the actual approver user.
