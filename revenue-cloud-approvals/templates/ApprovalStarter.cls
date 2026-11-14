// Per-process starter.
// There is no invocable action to submit an Advanced Approvals process, and an ApprovalWorkflow cannot be called
// from a Flow Action element, so an Apex invocable method launches it through Flow.Interview.
public without sharing class <Object><Domain>ApprovalStarter {
    public class Request {
        @InvocableVariable(required=true label='Record Id')
        public Id recordId;
        @InvocableVariable(label='Submission Comments')
        public String comments;
    }

    public class Result {
        @InvocableVariable(label='Message')
        public String message;
    }

    @InvocableMethod(label='Submit <Object> for <Domain> Approval' description='Starts <ApprovalFlowApiName>.')
    public static List<Result> submit(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            results.add(start(req));
        }
        return results;
    }

    private static Result start(Request req) {
        Result res = new Result();
        // Pre-submit guard: one active submission per record.
        Integer pending = [SELECT COUNT() FROM ApprovalSubmission WHERE RelatedRecordId = :req.recordId AND Status IN ('InProgress', 'Suspended')];
        if (pending > 0) {
            res.message = 'Approval already pending for this record.';
            return res;
        }

        // firstApprover is mandatory on every ApprovalWorkflow (see SKILL.md, Deployment Contract rule 1).
        Map<String, Object> inputs = new Map<String, Object>{
            'recordId' => req.recordId,
            'submitter' => UserInfo.getUserId(),
            'firstApprover' => UserInfo.getUserName(),
            'submissionComments' => req.comments
        };
        Flow.Interview.createInterview('<ApprovalFlowApiName>', inputs).start();
        res.message = 'Submitted for approval.';
        return res;
    }
}
