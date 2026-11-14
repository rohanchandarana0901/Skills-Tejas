public without sharing class ApprovalWorkItemSharingService {
    /*
     * Official "Share Temporary Access to Records in Advanced Approvals" pattern.
     * Source: help.salesforce.com articleView?id=ind.approvals_share_records_using_triggers.htm
     *
     * Grants record access to the approver when an ApprovalWorkItem is assigned
     * (share row on the related record) and withdraws it when the work item
     * reaches a terminal status (deletes the share row).
     *
     * This is a corrected, bulk-safe version of the help article sample, which
     * queries share rows without deleting them and runs SOQL inside a loop.
     *
     * TODO_VERIFY_IN_ORG:
     * - ApprovalWorkItem status values for "assigned" and "terminal" states.
     * - For custom related objects, create an Apex sharing reason on each object
     *   (e.g. AdvancedApprovalTriggerShareReason) and keep CUSTOM_ROW_CAUSE in sync.
     * - AccessLevel: Read is usually sufficient; use Edit only if approvers must
     *   modify the related record during approval.
     */

    // Apex sharing reasons apply to custom objects only. Standard share objects
    // (QuoteShare, OrderShare, ...) only accept RowCause = 'Manual' from Apex.
    private static final String CUSTOM_ROW_CAUSE = 'AdvancedApprovalTriggerShareReason__c';
    private static final String STANDARD_ROW_CAUSE = 'Manual';
    private static final String ACCESS_LEVEL = 'Read';

    public static void grantTemporaryAccess(List<ApprovalWorkItem> workItems) {
        List<SObject> sharesToInsert = new List<SObject>();

        for (ApprovalWorkItem awi : workItems) {
            if (awi.RelatedRecordId == null || awi.AssignedToId == null) {
                continue;
            }

            Schema.SObjectType shareType = resolveShareType(awi.RelatedRecordId);
            if (shareType == null) {
                // No share object => OWD is Public Read/Write; no share needed.
                continue;
            }

            SObject shareRow = shareType.newSObject();
            shareRow.put('ParentId', awi.RelatedRecordId);
            shareRow.put('UserOrGroupId', awi.AssignedToId);
            shareRow.put('AccessLevel', ACCESS_LEVEL);
            shareRow.put('RowCause', rowCauseFor(awi.RelatedRecordId));
            sharesToInsert.add(shareRow);
        }

        if (!sharesToInsert.isEmpty()) {
            // allOrNone=false: duplicate share rows fail individually without
            // blocking the rest of the batch.
            Database.SaveResult[] results = Database.insert(sharesToInsert, false);
            logFailures(results, 'grantTemporaryAccess');
        }
    }

    public static void revokeTemporaryAccess(List<ApprovalWorkItem> workItems) {
        // Group work items by share object so each share type is queried once.
        Map<String, Set<Id>> shareNameToParentIds = new Map<String, Set<Id>>();
        Map<String, Set<Id>> shareNameToUserIds = new Map<String, Set<Id>>();
        Map<String, Set<String>> shareNameToPairKeys = new Map<String, Set<String>>();

        for (ApprovalWorkItem awi : workItems) {
            if (awi.RelatedRecordId == null || awi.AssignedToId == null) {
                continue;
            }

            Schema.SObjectType shareType = resolveShareType(awi.RelatedRecordId);
            if (shareType == null) {
                continue;
            }

            String shareName = shareType.getDescribe().getName();
            if (!shareNameToParentIds.containsKey(shareName)) {
                shareNameToParentIds.put(shareName, new Set<Id>());
                shareNameToUserIds.put(shareName, new Set<Id>());
                shareNameToPairKeys.put(shareName, new Set<String>());
            }
            shareNameToParentIds.get(shareName).add(awi.RelatedRecordId);
            shareNameToUserIds.get(shareName).add(awi.AssignedToId);
            shareNameToPairKeys.get(shareName).add(awi.RelatedRecordId + ':' + awi.AssignedToId);
        }

        List<SObject> sharesToDelete = new List<SObject>();

        for (String shareName : shareNameToParentIds.keySet()) {
            Set<Id> parentIds = shareNameToParentIds.get(shareName);
            Set<Id> userOrGroupIds = shareNameToUserIds.get(shareName);
            Set<String> pairKeys = shareNameToPairKeys.get(shareName);
            String rowCause = shareName.endsWith('__Share') ? CUSTOM_ROW_CAUSE : STANDARD_ROW_CAUSE;

            // RowCause filter keeps the delete scoped to approval-time shares;
            // manual or rule-based shares are never touched.
            for (SObject shareRow : Database.query(
                'SELECT Id, ParentId, UserOrGroupId FROM ' + String.escapeSingleQuotes(shareName) +
                ' WHERE RowCause = :rowCause' +
                ' AND ParentId IN :parentIds' +
                ' AND UserOrGroupId IN :userOrGroupIds'
            )) {
                // The IN x IN query over-matches across pairs; keep only the
                // exact (record, approver) pairs being revoked.
                String key = shareRow.get('ParentId') + ':' + shareRow.get('UserOrGroupId');
                if (pairKeys.contains(key)) {
                    sharesToDelete.add(shareRow);
                }
            }
        }

        if (!sharesToDelete.isEmpty()) {
            Database.DeleteResult[] results = Database.delete(sharesToDelete, false);
            for (Database.DeleteResult dr : results) {
                if (!dr.isSuccess()) {
                    for (Database.Error err : dr.getErrors()) {
                        System.debug(LoggingLevel.WARN,
                            '[ApprovalWorkItemSharingService] revokeTemporaryAccess delete failed: ' +
                            err.getMessage());
                    }
                }
            }
        }
    }

    private static Schema.SObjectType resolveShareType(Id relatedRecordId) {
        Schema.DescribeSObjectResult related = relatedRecordId.getSObjectType().getDescribe();
        String shareName = related.isCustom()
            ? related.getName().removeEnd('__c') + '__Share'
            : related.getName() + 'Share';
        return Schema.getGlobalDescribe().get(shareName);
    }

    private static String rowCauseFor(Id relatedRecordId) {
        return relatedRecordId.getSObjectType().getDescribe().isCustom()
            ? CUSTOM_ROW_CAUSE
            : STANDARD_ROW_CAUSE;
    }

    private static void logFailures(Database.SaveResult[] results, String context) {
        for (Database.SaveResult sr : results) {
            if (!sr.isSuccess()) {
                for (Database.Error err : sr.getErrors()) {
                    System.debug(LoggingLevel.WARN,
                        '[ApprovalWorkItemSharingService] ' + context + ' failed: ' +
                        err.getMessage());
                }
            }
        }
    }
}
