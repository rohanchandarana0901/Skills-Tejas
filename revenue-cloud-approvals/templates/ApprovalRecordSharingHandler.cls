public with sharing class ApprovalRecordSharingHandler {
    public static void handleAfterChange(
        Map<Id, SObject> newMap,
        Map<Id, SObject> oldMap
    ) {
        if (newMap == null || newMap.isEmpty()) {
            return;
        }

        Set<Id> recordIdsNeedingSharing = new Set<Id>();

        for (SObject record : newMap.values()) {
            SObject oldRecord = oldMap == null ? null : oldMap.get(record.Id);

            /*
             * TODO_VERIFY_IN_ORG:
             * isPendingApproval() in the service must check the target org's
             * approval status field/value.
             */
            Boolean pending = ApprovalRecordSharingService.isPendingApproval(record);
            Boolean becamePending = pending &&
                (oldRecord == null || !ApprovalRecordSharingService.isPendingApproval(oldRecord));

            if (becamePending) {
                recordIdsNeedingSharing.add(record.Id);
            }
        }

        if (!recordIdsNeedingSharing.isEmpty()) {
            ApprovalRecordSharingService.shareWithApprovers(recordIdsNeedingSharing);
        }
    }
}
