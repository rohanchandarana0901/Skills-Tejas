# Enterprise Approval Design Checklist

## Requirement

- [ ] Execution trigger model confirmed: record-triggered OR auto-launched / manually invoked.
- [ ] If record-triggered: entry filter, recursion prevention, and duplicate submission guard designed.
- [ ] If auto-launched: invocation mechanism (button / Screen Flow / Apex / subflow) defined.
- [ ] Approval type identified.
- [ ] Approval driver identified.
- [ ] Approval routing source identified.
- [ ] Serial/parallel/hybrid pattern selected.
- [ ] Smart Approval applicability assessed.
- [ ] Record locking/editing strategy defined.
- [ ] Rejection behavior defined.
- [ ] Same approver role in 2+ steps or stages? If yes, consolidation decision recorded (Pre-Flight row 12; default is no change).

## Flow Design

- [ ] Data subflow outputs required values.
- [ ] Requires Approval decision updated.
- [ ] stepApproval entry conditions correct.
- [ ] Completion formula follows OR(not_required, completed).
- [ ] Stage exit logic updated safely.
- [ ] Rejection formula includes all rejecting steps.
- [ ] Fault handling exists.
- [ ] Status update paths exist.

## Security / Setup

- [ ] Public groups exist.
- [ ] Approvers active.
- [ ] Permission sets assigned.
- [ ] AA chains active.
- [ ] Use Smart Approval selected on each eligible step, and Use Advanced Approvals on for the org.
- [ ] Submit action visible.
- [ ] Approval component visible.

## Testing

- [ ] No approval path.
- [ ] Each tier individually.
- [ ] Parallel chains independently.
- [ ] Combined chains.
- [ ] Rejection each chain.
- [ ] Resubmission and Smart Approval.
- [ ] Missing approver.
- [ ] Fault simulation.
- [ ] Deployment validation.

## Deployment

- [ ] Metadata deployed in correct order.
- [ ] All approval flows Active.
- [ ] Draft flows not promoted unintentionally.
- [ ] Post-deploy smoke tests complete.
- [ ] Rollback plan documented.

# Rule-Based Auto-Approvals Checklist

## Prerequisites

- [ ] Advanced Approvals enabled.
- [ ] User has Approval Designer or Manage Flow.
- [ ] Approval workflow has at least one stage.
- [ ] Target approval step exists.
- [ ] Background step can be added before target approval step.
- [ ] Apex class `ApprovalPreviousRelatedRecordDetails` deployed.
- [ ] Autolaunched evaluation Flow created.
- [ ] Target step supports custom logic for auto-approvals.

## Apex

- [ ] Uses standard action `getPreviousRelaRecDetails`.
- [ ] Passes `flowOrchestrationInstanceId`.
- [ ] Passes `stepApiNamesList`.
- [ ] Handles no result safely.
- [ ] Handles action failure safely.
- [ ] Returns empty list rather than throwing unless fail-fast is required.

## Evaluation Flow

- [ ] Default `varCanAutoApprove = false`.
- [ ] Retrieves previous related record details.
- [ ] Compares current and previous values.
- [ ] Applies materiality rules.
- [ ] Outputs Boolean decision.
- [ ] Outputs diagnostic reason.
- [ ] Routes to manual review on uncertainty.

## Approval Workflow

- [ ] Background step precedes target approval step.
- [ ] Background step runs custom autolaunched Flow.
- [ ] Background step runs as Automated Process User.
- [ ] Target step starts when background step completes.
- [ ] Target step references background step API name.
- [ ] Target step has custom auto-approval logic enabled.
- [ ] Auto-Approve Step points to Boolean output.

## Testing

- [ ] First submission requires manual approval.
- [ ] Unchanged resubmission auto-approves.
- [ ] Material change requires manual review.
- [ ] Missing previous data requires manual review.
- [ ] Apex action failure requires manual review.
- [ ] Background step fault is handled.
- [ ] Audit/debug reason is visible.
