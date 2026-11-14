# Runtime Testing of a Deployed Approval Process

Use when Pre-Flight row 9 is "deploy and test". Create only test records the user can delete, name them with a common prefix (e.g. `<Prefix> Test ...`), and list them in the final report.

## Before creating test records

Describe every routing field the test data must set and confirm `createable` and `updateable` are true for the test user. A calculated field cannot be set; stop and follow Pre-Flight row 18 instead of working around it. After creating the records, query them back and confirm the routing fields hold the intended values.

## Procedure

1. **Create test records** covering each routing case, then start each through the real starter (the Apex starter or the flow behind the button), not by inserting approval records.
2. **Read work items:** `SELECT Status, AssignedTo.Name, CreatedDate FROM ApprovalWorkItem WHERE RelatedRecordId = '<id>' ORDER BY CreatedDate`. `AssignedTo.Name` shows the queue; `Status` is `Assigned`, `Approved` or `Rejected`.
3. **Approve or reject** an `Assigned` work item through the standard action `reviewApprovalWorkItem` (REST `POST /services/data/latest/actions/standard/reviewApprovalWorkItem` with `inputs: [{approvalWorkItemId, approvalDecision: "Approve"|"Reject", comments}]`, or the Revenue Cloud MCP tool of the same name).
4. **Poll, do not assume.** Each serial step can take about 10 to 45 seconds to create the next work item, and the outcome status write is also asynchronous. Re-query before calling a result a failure.
5. **Check the outcome field** on the record after the last decision.

## Test harness notes

- Pass a literal `--target-org <alias>` on every command.
- Write helper scripts for `bash` (`#!/bin/bash`). In zsh, `set -- $var` does not split on spaces, which silently created records with blank routing fields (they then correctly took the nothing-required path and looked like a process bug). Loop with `while read -r a b c` instead.
- After creating test records, query them back and confirm the routing fields hold the intended values before submitting.
- A resubmission with a status write at submit sets the status again (for example back to In Review) even though earlier steps are auto-approved.

## Known behavior (observed)

- Approving through `reviewApprovalWorkItem` works for queue-assigned items even when the queue has no members; real users in the UI still need queue membership. Queue membership is decided in Pre-Flight row 21; add members only as chosen there.
- On resubmission with Smart Approval, steps whose start conditions are unchanged appear as new work items that are already `Approved` within about a second; only changed or previously rejected steps get an `Assigned` item.
- A status field the process writes only at the end (Approved/Rejected) keeps its old value while a resubmitted approval is pending.
- A rejection at any step ends the process and later steps never create work items.

## Cases to cover (adapt to the design)

Each routing branch alone, the full serial chain, an independent step with no level, nothing required, a rejection mid-chain, and a resubmission after rejection (Smart Approval).

## Report

Components created, test records created, one result per case (expected vs actual), deployment status, limitations. Offer to delete the test records; do not delete without a yes. Note that state whether the quick action was placed (Pre-Flight row 20) and which queues have members (row 21).
