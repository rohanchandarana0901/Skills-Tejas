// Generic starter: one class for any ApprovalWorkflow; the flow API name is an input of the caller.
// Use only when the user chose a shared starter (Pre-Flight row 13). The calling screen flow or quick action must
// hard-code the flow name it launches. Do not expose the flow name to end users: this class starts any flow it is given.
public without sharing class GenericApprovalStarter {
    public class Request {
        @InvocableVariable(required=true label='Approval Flow API Name')
        public String flowName;
        @InvocableVariable(required=true label='Record Id')
        public Id recordId;
        @InvocableVariable(label='Submission Comments')
        public String comments;
    }

    public class Result {
        @InvocableVariable(label='Message')
        public String message;
    }

    @InvocableMethod(label='Submit Record for Approval (generic)' description='Starts the ApprovalWorkflow named in flowName.')
    public static List<Result> submit(List<Request> requests) {
        List<Result> results = new List<Result>();
        for (Request req : requests) {
            Result res = new Result();
            Integer pending = [SELECT COUNT() FROM ApprovalSubmission WHERE RelatedRecordId = :req.recordId AND Status IN ('InProgress', 'Suspended')];
            if (pending > 0) {
                res.message = 'Approval already pending for this record.';
            } else {
                Map<String, Object> inputs = new Map<String, Object>{
                    'recordId' => req.recordId,
                    'submitter' => UserInfo.getUserId(),
                    'firstApprover' => UserInfo.getUserName(),
                    'submissionComments' => req.comments
                };
                Flow.Interview.createInterview(req.flowName, inputs).start();
                res.message = 'Submitted for approval.';
            }
            results.add(res);
        }
        return results;
    }
}
