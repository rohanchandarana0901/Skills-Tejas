public without sharing class ApprovalPreviousRelatedRecordDetails {
    /*
     * Wrapper for Salesforce standard invocable action:
     * getPreviousRelaRecDetails
     *
     * Purpose:
     * Retrieve related record details submitted for approval before the current
     * approval submission. Used by Rule-Based Auto-Approvals to compare current
     * submission data with previous submitted data.
     *
     * Usage:
     * Invoke this Apex action from an autolaunched Flow that runs in a background
     * step before the target approval step.
     *
     * Input behaviour:
     * Both flowOrchestrationInstanceId and stepApiNamesList are OPTIONAL.
     * They are set on the standard action only when provided (non-null / non-blank).
     *
     * When called from a background step (most common case):
     * - Do NOT pass flowOrchestrationInstanceId from the evaluator flow.
     *   $Flow.OrchestrationInstanceId is not accessible in AutoLaunchedFlow and
     *   cannot be passed through background step inputParameters (type mismatch
     *   at deploy time). The standard action inherits the orchestration context
     *   automatically from the background step execution environment.
     * - Do NOT pass stepApiNamesList from the evaluator flow.
     *   Collection-typed inputs cannot be passed from an orchestration background
     *   step to an AutoLaunchedFlow input (deploy error). The standard action
     *   returns all previous step details when stepApiNamesList is omitted.
     *
     * When called from non-background-step contexts (e.g. Apex, Screen Flow,
     * subflow outside orchestration):
     * - flowOrchestrationInstanceId and stepApiNamesList can be passed explicitly.
     */

    private static final String ACTION_NAME = 'getPreviousRelaRecDetails';
    private static final String ACTION_INPUT_PARAM_FOI_ID = 'flowOrchestrationInstanceId';
    private static final String ACTION_INPUT_PARAM_STEP_API_NAMES = 'stepApiNamesList';
    private static final String ACTION_OUTPUT_PARAM_PREVIOUS_RECORD_DETAILS = 'previousRelatedRecordDetails';

    @InvocableMethod(
        label='Get Previous Related Record Details'
        description='Gets related record details submitted for approval before the current submission. flowOrchestrationInstanceId and stepApiNamesList are optional — when called from a background step the platform resolves orchestration context automatically.'
    )
    public static List<List<SObject>> getPreviousRelaRecDetails(List<FlowInputs> flowInputs) {
        List<List<SObject>> response = new List<List<SObject>>();

        if (flowInputs == null || flowInputs.isEmpty()) {
            response.add(new List<SObject>());
            return response;
        }

        FlowInputs input = flowInputs[0];

        try {
            Invocable.Action action = Invocable.Action.createStandardAction(ACTION_NAME);

            if (!String.isBlank(input.flowOrchestrationInstanceId)) {
                action.setInvocationParameter(ACTION_INPUT_PARAM_FOI_ID, input.flowOrchestrationInstanceId);
            }
            if (input.stepApiNamesList != null && !input.stepApiNamesList.isEmpty()) {
                action.setInvocationParameter(ACTION_INPUT_PARAM_STEP_API_NAMES, input.stepApiNamesList);
            }

            List<Invocable.Action.Result> results = action.invoke();

            if (results == null || results.isEmpty()) {
                response.add(new List<SObject>());
                return response;
            }

            Invocable.Action.Result result = results[0];

            if (result.isSuccess()) {
                Object outputValue = result.getOutputParameters().get(ACTION_OUTPUT_PARAM_PREVIOUS_RECORD_DETAILS);

                if (outputValue instanceof List<SObject>) {
                    response.add((List<SObject>) outputValue);
                } else {
                    response.add(new List<SObject>());
                }
            } else {
                for (Invocable.Action.Error error : result.getErrors()) {
                    System.debug(LoggingLevel.WARN,
                        '[ApprovalPreviousRelatedRecordDetails] getPreviousRelaRecDetails failed: ' +
                        error.getMessage()
                    );
                }
                response.add(new List<SObject>());
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR,
                '[ApprovalPreviousRelatedRecordDetails] Unexpected error: ' +
                ex.getMessage() + ' | ' + ex.getStackTraceString()
            );
            response.add(new List<SObject>());
        }

        return response;
    }

    public class FlowInputs {
        @InvocableVariable(
            label='Flow Orchestration Instance Id'
            description='Optional. The $Flow.OrchestrationInstanceId from the orchestration flow. When called from a background step, leave blank — the platform resolves context automatically. Only provide when calling from outside an orchestration background step.'
            required=false
        )
        public String flowOrchestrationInstanceId;

        @InvocableVariable(
            label='Step API Names List'
            description='Optional. Approval step API names to scope the lookup. Cannot be passed from a background step inputParameter (collection type not supported). Leave blank to return details for all previous steps.'
            required=false
        )
        public List<String> stepApiNamesList;
    }

    public class InvocableActionException extends Exception {}
}
