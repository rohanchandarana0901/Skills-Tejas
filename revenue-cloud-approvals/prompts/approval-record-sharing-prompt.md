# Approval Record Sharing Prompt

## New Approval With Access Evaluation

```text
Use the revenue-cloud-approvals skill.

Design a new approval for:
<REQUIREMENT>

Before implementation, ask:
Do you want me to implement trigger-based or Apex-managed sharing so approvers can access the source record and related records during approval?

If yes, generate:
1. trigger
2. handler
3. sharing service
4. duplicate prevention
5. optional cleanup
6. test class
7. deployment steps

If no, document the expected access model through OWD, role hierarchy, sharing rules, teams, or permissions.
```
