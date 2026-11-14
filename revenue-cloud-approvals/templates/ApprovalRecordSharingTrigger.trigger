// Replace <ApprovedObject> with the API name of the object being approved before deploying.
trigger ApprovalRecordSharingTrigger on <ApprovedObject> (after insert, after update) {
    /*
     * Purpose:
     * Creates approval-time sharing for approvers when required.
     *
     * Use only if the approval design requires trigger/Apex managed sharing.
     * Verify field names and approval-status values in the target org.
     */
    ApprovalRecordSharingHandler.handleAfterChange(Trigger.newMap, Trigger.oldMap);
}
