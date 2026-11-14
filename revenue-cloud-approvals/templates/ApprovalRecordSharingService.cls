public with sharing class ApprovalRecordSharingService {
    /*
     * TODO_VERIFY_IN_ORG: set the configuration below for the approved object,
     * and replace the placeholder status check and approver resolution.
     */

    // Share object API name: custom objects use <Object>__Share; standard objects use <Object>Share.
    private static final String SHARE_OBJECT = '<ApprovedObject>Share';
    // Parent lookup on the share object: custom objects use ParentId; standard objects use <Object>Id.
    private static final String PARENT_FIELD = 'ParentId';
    // Access field on the share object: custom objects use AccessLevel; standard objects use <Object>AccessLevel.
    private static final String ACCESS_FIELD = 'AccessLevel';
    private static final String ACCESS_LEVEL = 'Edit';
    // Standard share objects accept only Manual; custom objects can use an Apex sharing reason.
    private static final String ROW_CAUSE = 'Manual';

    public static Boolean isPendingApproval(SObject record) {
        if (record == null) {
            return false;
        }

        // Example placeholder. Replace with the target approval status check.
        // return (String) record.get('<approval-status-field>') == '<pending-value>';

        return false;
    }

    public static void shareWithApprovers(Set<Id> recordIds) {
        if (recordIds == null || recordIds.isEmpty()) {
            return;
        }

        Map<Id, Set<Id>> recordIdToApproverIds = resolveApprovers(recordIds);
        Set<String> existingKeys = getExistingShareKeys(recordIdToApproverIds);
        List<SObject> sharesToInsert = new List<SObject>();
        Schema.SObjectType shareType = Schema.getGlobalDescribe().get(SHARE_OBJECT);

        for (Id recordId : recordIdToApproverIds.keySet()) {
            for (Id approverId : recordIdToApproverIds.get(recordId)) {
                if (approverId == null || existingKeys.contains(recordId + ':' + approverId)) {
                    continue;
                }

                SObject shareRow = shareType.newSObject();
                shareRow.put(PARENT_FIELD, recordId);
                shareRow.put('UserOrGroupId', approverId);
                shareRow.put(ACCESS_FIELD, ACCESS_LEVEL);
                shareRow.put('RowCause', ROW_CAUSE);
                sharesToInsert.add(shareRow);
            }
        }

        if (!sharesToInsert.isEmpty()) {
            for (Database.SaveResult sr : Database.insert(sharesToInsert, false)) {
                if (!sr.isSuccess()) {
                    for (Database.Error err : sr.getErrors()) {
                        System.debug(LoggingLevel.WARN,
                            '[ApprovalRecordSharingService] Failed to create share: ' + err.getMessage());
                    }
                }
            }
        }
    }

    private static Map<Id, Set<Id>> resolveApprovers(Set<Id> recordIds) {
        Map<Id, Set<Id>> result = new Map<Id, Set<Id>>();
        for (Id recordId : recordIds) {
            result.put(recordId, new Set<Id>());
        }

        /*
         * TODO_VERIFY_IN_ORG: replace with actual approver resolution.
         * Possible sources: Advanced Approval work items (AssignedToId), an approval matrix,
         * public group members, approver lookup fields, manager hierarchy.
         */

        return result;
    }

    private static Set<String> getExistingShareKeys(Map<Id, Set<Id>> recordIdToApproverIds) {
        Set<String> keys = new Set<String>();
        if (recordIdToApproverIds == null || recordIdToApproverIds.isEmpty()) {
            return keys;
        }

        Set<Id> recordIds = recordIdToApproverIds.keySet();
        Set<Id> userOrGroupIds = new Set<Id>();
        for (Set<Id> approverIds : recordIdToApproverIds.values()) {
            userOrGroupIds.addAll(approverIds);
        }
        if (userOrGroupIds.isEmpty()) {
            return keys;
        }

        String soql = 'SELECT ' + PARENT_FIELD + ', UserOrGroupId FROM ' + SHARE_OBJECT +
            ' WHERE ' + PARENT_FIELD + ' IN :recordIds AND UserOrGroupId IN :userOrGroupIds';
        for (SObject shareRow : Database.query(soql)) {
            keys.add((Id) shareRow.get(PARENT_FIELD) + ':' + (Id) shareRow.get('UserOrGroupId'));
        }
        return keys;
    }

    public static void removeApprovalShares(Set<Id> recordIds, Set<Id> approverIds) {
        /*
         * Optional cleanup. Use only if business/security requires removing shares after
         * approval completes, is recalled, or is canceled.
         */
        if (recordIds == null || recordIds.isEmpty() || approverIds == null || approverIds.isEmpty()) {
            return;
        }

        String soql = 'SELECT Id FROM ' + SHARE_OBJECT +
            ' WHERE ' + PARENT_FIELD + ' IN :recordIds AND UserOrGroupId IN :approverIds' +
            ' AND RowCause = :ROW_CAUSE';
        List<SObject> sharesToDelete = Database.query(soql);
        if (!sharesToDelete.isEmpty()) {
            Database.delete(sharesToDelete, false);
        }
    }
}
