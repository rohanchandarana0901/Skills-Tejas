public without sharing class AutoApprovalCustomLogicDecision {
    /*
     * Template for Salesforce Flow Approval custom logic for auto-approvals.
     *
     * IMPORTANT OUTPUT CONTRACT SIGNATURES
     * -----------------------------------
     * A. FLAT SIGNATURE (Recommended for Autolaunched Evaluator Flow Wrapper):
     *    Use: `public static List<Output> evaluate(List<Input> inputs)`
     *    Allows direct scalar mapping (e.g. `{!Evaluate_Levels.canAutoApprove}`)
     *    in Flow assignments via storeOutputAutomatically=true without looping.
     *
     * B. NESTED SIGNATURE (Required for collection-style looping outputs):
     *    Use: `public static List<List<Output>> evaluate(List<Input> inputs)`
     *    Salesforce maps this to a Collection variable in Flow. If you attempt
     *    to bind scalar variables to nested outputs directly, deployment will
     *    fail with a field integrity exception (unknown invalid reference).
     */

    @InvocableMethod(
        label='Evaluate Auto Approval Custom Logic'
        description='Returns auto-approval decision output for Flow Approval custom logic.'
    )
    public static List<Output> evaluate(List<Input> inputs) {
        List<Output> responses = new List<Output>();

        if (inputs == null || inputs.isEmpty()) {
            responses.add(Output.manualReview('No input received.'));
            return responses;
        }

        for (Input request : inputs) {
            Output result = new Output();
            result.canAutoApprove = false;
            result.evaluationReason = null;
            result.manualReviewReason = 'Manual review required by default.';

            try {
                // Replace this sample rule with the project-specific comparison logic.
                // Sample: auto-approve only when the routing value did not increase and the
                // optional fingerprint of approval-relevant fields is unchanged.
                if (request.previousRoutingValue != null && request.currentRoutingValue != null
                    && request.currentRoutingValue <= request.previousRoutingValue
                    && request.currentFingerprint == request.previousFingerprint) {
                    result.canAutoApprove = true;
                    result.evaluationReason = 'No approval-material increase detected.';
                    result.manualReviewReason = null;
                } else {
                    result.manualReviewReason = 'Approval-material change detected or previous values are missing.';
                }
            } catch (Exception ex) {
                result.canAutoApprove = false;
                result.manualReviewReason = 'Auto-approval evaluation failed: ' + ex.getMessage();
            }

            // Flat output structure.
            responses.add(result);
        }

        return responses;
    }

    public class Input {
        @InvocableVariable(label='Current Routing Value' description='Numeric value the approval routes on, e.g. a level or amount.')
        public Decimal currentRoutingValue;

        @InvocableVariable(label='Previous Routing Value')
        public Decimal previousRoutingValue;

        @InvocableVariable(label='Current Fingerprint' description='Optional hash of approval-relevant fields.')
        public String currentFingerprint;

        @InvocableVariable(label='Previous Fingerprint')
        public String previousFingerprint;
    }

    public class Output {
        @InvocableVariable(label='Can Auto Approve')
        public Boolean canAutoApprove;

        @InvocableVariable(label='Evaluation Reason')
        public String evaluationReason;

        @InvocableVariable(label='Manual Review Reason')
        public String manualReviewReason;

        public static Output manualReview(String reason) {
            Output output = new Output();
            output.canAutoApprove = false;
            output.manualReviewReason = reason;
            return output;
        }
    }
}
