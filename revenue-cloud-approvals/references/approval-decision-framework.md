# Approval Design Decision Framework

## 1. Identify approval category

- Discount
- Margin
- Specialist/payment terms
- Legal terms
- Product exception
- Region/country compliance
- Contract terms
- Billing/commercial risk
- Customer risk

## 2. Identify approval driver

Examples:

- discount percent
- net total
- non-standard payment terms
- non-standard legal clause
- low margin
- restricted product
- non-standard billing frequency
- manual price override

## 3. Determine approver source

Choose one:

| Source | Use when |
|---|---|
| Public Group | broad role-based approval |
| Named User | fixed owner, rare |
| Level 1 Approver hierarchy | approval follows submitter/owner reporting line |
| Matrix object | approver varies by dimensions |
| Custom Metadata | governance-managed rules |
| Queue/Group | any member may approve |
| Dynamic lookup | record stores approver |

## 4. Determine execution model

| Model | Use when |
|---|---|
| Serial | lower approval must complete before higher tier |
| Parallel | independent reviews can happen together |
| Hybrid | multiple chains with serial tiers inside each |
| Any-one group approval | one approver from group is enough |
| All approvers | every named approver must decide |

## 5. Determine Smart Approval applicability

Smart Approval is appropriate when:

- same record may be resubmitted
- repeated approval adds little value
- materiality logic is clear
- governance accepts skip behavior

Smart Approval is risky when:

- legal/compliance review must always re-run
- approver authority changed
- approval condition worsened
- source record changes are broad/uncontrolled

## 6. Define status model

Recommended values:

```text
Draft
Ready for Approval
Pending
Approved
Rejected
Recalled
Approval Error
```

Map these to actual org fields and values.

## 7. Define failure behavior

Every design must answer:

- what happens if data retrieval fails?
- what happens if approver group is empty?
- what happens if status update fails?
- what happens if Flow interview faults?
- how is the submitter notified?
- how is the admin notified?
