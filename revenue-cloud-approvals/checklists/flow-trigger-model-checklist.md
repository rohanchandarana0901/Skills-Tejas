# Flow Trigger Model Checklist

Use this checklist before generating or changing any Revenue Cloud Advanced Approval implementation.

## Required Question

Ask the user:

> Should this approval start automatically from a record change, or should it be launched manually/from another process?

## If Record-Triggered Starter

Confirm:

- Source object, for example Quote, Order, Contract, Sales Transaction, or custom object
- Trigger timing, normally after-save
- Entry criteria
- Changed-to-meet-criteria behavior
- Recursion guard
- Duplicate approval submission guard
- Whether the starter only submits/launches the ApprovalWorkflow

Do not place the full approval chain inside the Record-Triggered Flow.

## If Auto-Launched / Manual Starter

Confirm:

- Invocation source: button, Screen Flow, Apex, API, scheduled process, or another flow
- Input variables, especially record Id
- Output variables or status updates required
- Whether user preview/submission UI is needed

## If Auto-Approval Rule Logic

Confirm:

- Whether the Flow is invoked from a background step
- Required previous-submission comparison fields
- Apex invocable output shape

For invocable Apex used by Flow, determine output shape:
- Recommended (Pattern A — flat, scalar binding):
  ```apex
  @InvocableMethod
  public static List<Output> evaluate(List<Input> inputs) {
      List<Output> results = new List<Output>();
      // populate results
      return results;
  }
  ```
- Collection-style (Pattern B — nested, loops in Flow):
  ```apex
  @InvocableMethod
  public static List<List<Output>> evaluate(List<Input> inputs) {
      List<Output> results = new List<Output>();
      // populate results
      return new List<List<Output>>{ results };
  }
  ```
Do not attempt to map scalar variables directly to nested (Pattern B) action outputs in the Flow, otherwise deployment will fail with a field integrity exception (unknown invalid reference).
