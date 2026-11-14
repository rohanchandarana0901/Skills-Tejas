# Stage layouts: explain to the user before asking row 10 or row 11

Show this (adapt the names to the user's approval) whenever row 10 or row 11 is asked:

```text
SINGLE STAGE (default, recommended)
  Gather data -> [ ONE approvals stage:  Level 1 -> Level 2 -> Level 3
                                         Independent approval A   (runs alongside)
                                         Independent approval B   (runs alongside) ] -> Decision -> Approved / Rejected
  - Steps in the stage start whenever their own start conditions are met.
  - Serial order = a step starts only after the previous step is approved.
  - Independent approvals start with the chain and never block it, and the chain never blocks them.
  - The final decision waits until every required step is decided.

MULTI-STAGE (you choose which steps go in each stage; example grouping shown)
  Gather data -> [Stage 1: Level 1 + Independent A + Independent B] -> [Stage 2: Level 2] -> [Stage 3: Level 3] -> Decision -> Approved / Rejected
  - Steps inside one stage still run side by side.
  - A stage is a barrier: the next stage starts only after EVERY required step in the
    previous stage is complete (so Level 2 waits for the independent approvals too).
  - One stage per level is the same layout with a single step in each stage.
  - A rejection inside a stage still lets the other steps in that stage finish first.
```

Recommend single stage. Tell the user the consequence in one line: single stage keeps independent approvals fully parallel with the chain; multi-stage gives clearer phases but later stages wait for everything in the earlier stage, so choose it only if that wait is acceptable. If they choose multi-stage, ask which steps go in each stage.
