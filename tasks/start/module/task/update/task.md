# Update Task

Update an existing task in the library repository. This is primarily a design and discussion process — understanding what the task is doing wrong or not doing, and agreeing on the changes before implementing them.

## Prerequisites

- The task path under tasks/ (e.g., `jira/item/comment/git-commit`)
- Write access to the library repository
- CUE CLI installed (`cue version`)

## Process

Steps:

1. Identify the task to update
2. Read the current task files
3. Understand the problem
4. Design the changes
5. Implement the changes
6. Publish following the publishing workflow

## Step 1: Identify the Task

If a task path was supplied in the instructions, use it.

Otherwise, ask the user which task they want to update and confirm the full path under tasks/.

## Step 2: Read the Current Task Files

Read the existing files for the task:

- `tasks/<path>/task.md` — the task instructions
- `tasks/<path>/task.cue` — the CUE schema definition
- `tasks/<path>/cue.mod/module.cue` — the module definition

Summarise the current task behaviour to the user so they can confirm your understanding before proceeding.

## Step 3: Understand the Problem

Ask the user to describe what the task is doing wrong or what it is not doing.

Probe with questions if needed:

- Is the agent misunderstanding a step?
- Is a step missing or incomplete?
- Is the output format wrong?
- Is the confirmation or interaction behaviour off?
- Is there a new requirement to add?

Do not proceed until the problem is clearly understood.

## Step 4: Design the Changes

This is the core of the update process. Discuss the proposed changes with the user before writing anything.

- Describe what you plan to change and why
- If multiple changes are needed, discuss each one
- Confirm the approach with the user before proceeding
- Consider whether changes affect task.md only, or also task.cue

Do not implement until the design is agreed.

## Step 5: Implement the Changes

Apply the agreed changes to the task files.

If task.md is changing, update the relevant sections only — do not rewrite sections that are not affected.

If task.cue is changing (e.g., description, tags, prompt), update accordingly.

## Step 6: Publish

Before publishing, confirm the task is still complete after the change: `task.md` and `task.cue` remain consistent, the prompt pattern still fits the size of `task.md`, and any referenced role resolves.

Then load the publishing workflow and follow it end to end:

```bash
start get contexts:start/library/publishing
```

It is the single source for validation, version determination, the mandatory index update, the single module-plus-index commit, the tag pushes, the registry publish, verification, and closing any related GitHub issue.
