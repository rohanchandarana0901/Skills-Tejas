trigger ApprovalWorkItemSharingTrigger on ApprovalWorkItem (after insert, after update) {
    /*
     * Official temporary-access pattern for Advanced Approvals:
     * grant the approver access to the related record when the work item is
     * assigned, withdraw it when the work item completes.
     *
     * ApprovalWorkItem.Status standard values: Assigned (active), Approved,
     * Rejected, Recalled, Canceled, Withdrawn, Errored (terminal).
     */

    List<ApprovalWorkItem> toGrant = new List<ApprovalWorkItem>();
    List<ApprovalWorkItem> toRevoke = new List<ApprovalWorkItem>();

    Set<String> terminalStatuses = new Set<String>{
        'Approved', 'Rejected', 'Recalled', 'Canceled', 'Withdrawn', 'Errored'
    };

    for (ApprovalWorkItem awi : Trigger.new) {
        ApprovalWorkItem oldAwi = Trigger.isUpdate ? Trigger.oldMap.get(awi.Id) : null;

        Boolean newlyAssigned = awi.AssignedToId != null &&
            (oldAwi == null || oldAwi.AssignedToId != awi.AssignedToId);

        Boolean becameTerminal = terminalStatuses.contains(awi.Status) &&
            (oldAwi == null || !terminalStatuses.contains(oldAwi.Status));

        if (becameTerminal) {
            toRevoke.add(awi);
        } else if (newlyAssigned) {
            toGrant.add(awi);
        }
    }

    if (!toGrant.isEmpty()) {
        ApprovalWorkItemSharingService.grantTemporaryAccess(toGrant);
    }
    if (!toRevoke.isEmpty()) {
        ApprovalWorkItemSharingService.revokeTemporaryAccess(toRevoke);
    }
}
