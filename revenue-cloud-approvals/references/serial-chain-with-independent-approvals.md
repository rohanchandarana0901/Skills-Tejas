# Serial Chain With Independent Approvals (Verified Pattern)

Use when the request has a leveled management chain (Level 1, 2, 3 steps) and extra approvals (e.g. Legal, Finance) that are triggered only by their own checkbox or flag, not by the level, and "all approvals run serially". Illustrative names: replace objects, fields, queues and step names with the user's.

Verified in a target org on a Quote: routing, serial order, rejection, Smart Approval resubmission. Single approvals stage, so the independent approvals are not delayed by stage barriers.

## Rules the pattern follows

1. **Triggers stay independent.** Legal starts only because `IsLegalRequired = true`; Finance only because `IsFinanceRequired = true`. The level is never part of the trigger.
2. **Serial order comes from "the previous required step finished".** The previous required step depends on the level, so each independent step gets one branch per level.
3. **Leveled steps are cumulative by default** (level 2 = Level 1 step, then Level 2 step). State this assumption in the plan, or ask when the request is unclear (see Pre-Flight Rules, level routing).
4. **Gather subflow returns a null-safe level** (`blank` becomes `0`) plus the Boolean flags, so entry conditions stay direct comparisons.
5. **A rejection anywhere ends the process.** Later steps never start (their entry conditions need the previous `Approve`). Tell the user.

## Entry conditions (custom logic, direct comparisons only)

`L` = gather output `ApprovalLevel` (null-safe). `M`, `D`, `V` = Level 1/2/3 step `approvalDecision`.

Level 1 / 2 / 3 steps (cumulative):

```text
Step 1:  L >= 1
Step 2:  L >= 2  AND  Step1 = Approve
Step 3:  L >= 3  AND  Step2 = Approve
```

First independent step (Legal):

```text
entryConditionLogic = 1 AND (2 OR (3 AND 4) OR (5 AND 6) OR (7 AND 8))
1 = IsLegalRequired EqualTo true
2 = L LessThan 1                       (no leveled step: start now)
3 = L EqualTo 1     4 = M EqualTo "Approve"
5 = L EqualTo 2     6 = D EqualTo "Approve"
7 = L GreaterThanOrEqualTo 3   8 = V EqualTo "Approve"
```

Second independent step (Finance), after Legal when Legal is required:

```text
entryConditionLogic = 1 AND ((2 AND 3) OR (4 AND (5 OR (6 AND 7) OR (8 AND 9) OR (10 AND 11))))
1  = IsFinanceRequired EqualTo true
2  = IsLegalRequired EqualTo true     3  = Legal decision EqualTo "Approve"
4  = IsLegalRequired EqualTo false
5  = L LessThan 1
6  = L EqualTo 1   7 = M EqualTo "Approve"
8  = L EqualTo 2   9 = D EqualTo "Approve"
10 = L GreaterThanOrEqualTo 3   11 = V EqualTo "Approve"
```

## Formulas (used only in exit and rejection logic, never in entry conditions)

```text
IsMgmtDone = OR(L < 1, AND(L = 1, M = "Approve"), AND(L = 2, D = "Approve"), AND(L >= 3, V = "Approve"))
IsLegalRequiredNow   = AND(IsLegalRequired, IsMgmtDone)
IsFinanceRequiredNow = AND(IsFinanceRequired, IsMgmtDone, OR(NOT(IsLegalRequired), Legal = "Approve"))
IsApprovalsStageComplete = AND(
  OR(NOT(L >= 1),               NOT(ISBLANK(M))),
  OR(NOT(IsDirectorRequired),   NOT(ISBLANK(D))),    // L >= 2 AND M = Approve
  OR(NOT(IsVPRequired),         NOT(ISBLANK(V))),    // L >= 3 AND D = Approve
  OR(NOT(IsLegalRequiredNow),   NOT(ISBLANK(Legal))),
  OR(NOT(IsFinanceRequiredNow), NOT(ISBLANK(Finance))))
IsAnyRejected = OR(<every step>.Outputs.approvalDecision = "Reject")
```

A rejected step makes every later "required now" formula false, so the stage exits and the Decision after the stage routes to the Rejected outcome. When nothing is required all clauses are true and the stage exits at once.

## Test cases for this pattern

| Case | Expected |
|---|---|
| Level 1 only | Level 1 step, then Approved |
| Level 3 + Legal + Finance | Level 1, 2, 3, Legal, Finance, one at a time |
| Legal only, no level | Legal only |
| Finance only, no level | Finance only |
| Nothing required | Approved at once, no tasks |
| Reject Level 1 on a quote that also needs Finance | Rejected; no later task created |
| Reject Legal, resubmit unchanged | Earlier steps auto-approved, Legal asked again |

## Parallel variant (independent approvals start with the chain)

Use when Pre-Flight row 10 is "parallel with the chain, no dependency". Single stage. The independent steps have one direct entry condition each and never reference the level or another step:

```text
Legal step:    IsLegalRequired   EqualTo true
Finance step:  IsFinanceRequired EqualTo true
```

Exit formula adds one clause per independent step, using the gather outputs (not the "required now" formulas):

```text
OR(NOT(IsLegalRequired),   NOT(ISBLANK(Legal.Outputs.approvalDecision)))
OR(NOT(IsFinanceRequired), NOT(ISBLANK(Finance.Outputs.approvalDecision)))
```

Rejection formula still lists every step. A rejection in the level chain ends the chain, but an independent step that already started must still be decided before the stage exits and the outcome is written (verified).

### Gather subflow: null-safe level plus flags (illustrative)
Complete flow with start element, variables and labels: `templates/helper-flow-templates.md`. The fragment below shows the logic only.
Autolaunched flow, input `RecordId` (String), outputs `ApprovalLevel` (Number, scale 0), `IsLegalRequired`, `IsFinanceRequired` (Boolean). Map the user's own field names.

```xml
<assignments>
    <name>Set_Safe_Level</name>
    <label>Set Safe Level</label>
    <locationX>0</locationX>
    <locationY>0</locationY>
    <assignmentItems>
        <assignToReference>ApprovalLevel</assignToReference>
        <operator>Assign</operator>
        <value><elementReference>SafeLevel</elementReference></value>
    </assignmentItems>
</assignments>
<formulas>
    <name>SafeLevel</name>
    <dataType>Number</dataType>
    <expression>IF(ISBLANK({!rawLevel}), 0, {!rawLevel})</expression>
    <scale>0</scale>
</formulas>
<recordLookups>
    <name>Get_Record</name>
    <label>Get Record</label>
    <locationX>0</locationX>
    <locationY>0</locationY>
    <connector><targetReference>Set_Safe_Level</targetReference></connector>
    <filterLogic>and</filterLogic>
    <filters>
        <field>Id</field>
        <operator>EqualTo</operator>
        <value><elementReference>RecordId</elementReference></value>
    </filters>
    <getFirstRecordOnly>true</getFirstRecordOnly>
    <object><Object></object>
    <outputAssignments><assignToReference>rawLevel</assignToReference><field><LevelField></field></outputAssignments>
    <outputAssignments><assignToReference>IsLegalRequired</assignToReference><field><LegalCheckbox></field></outputAssignments>
    <outputAssignments><assignToReference>IsFinanceRequired</assignToReference><field><FinanceCheckbox></field></outputAssignments>
</recordLookups>
```
Declare `rawLevel` (Number, scale 0, not input or output), and give the three outputs default values (`0.0`, `false`, `false`). In the ApprovalWorkflow, the data step lists all three in `<outputConfigParams>` with `xsi:nil="true"`. Look up the real checkbox fields in the org first (field lookup rule in Deployment Contract rule 6); create them only if missing.
