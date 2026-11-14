# Trigger Sharing Implementation Checklist

## Ask First

- [ ] Asked whether trigger/Apex managed sharing should be implemented.
- [ ] User confirmed implementation is required.

## Access Model

- [ ] Trigger placement chosen: ApprovalWorkItem (official temporary-access default) vs source object.
- [ ] Source object OWD reviewed.
- [ ] Related object access reviewed.
- [ ] Approver user/group source identified (ApprovalWorkItem pattern: `AssignedToId` — no custom resolver needed).
- [ ] Read vs Edit access decided.
- [ ] RowCause decided: Apex sharing reason for custom objects; `Manual` for standard share objects.
- [ ] Share cleanup decision made (required for temporary access — revoke on terminal work-item status).

## Implementation

- [ ] Trigger is bulk-safe.
- [ ] Handler has no SOQL/DML in loops.
- [ ] Service avoids duplicate shares.
- [ ] SaveResult errors are logged.
- [ ] Approver resolver is parameterized for the target org.
- [ ] TODO placeholders replaced.
- [ ] Tests cover multiple quotes and approvers.

## Testing

- [ ] Test as approver user.
- [ ] Approver can open source record.
- [ ] Approver can act on approval request.
- [ ] Existing shares are not duplicated.
- [ ] Recall/cancel/complete cleanup tested if implemented.
