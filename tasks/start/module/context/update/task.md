# Update Context

Update an existing context definition in the library repository. This is primarily a design and discussion process — understanding what the context is doing wrong or not doing, and agreeing on the changes before implementing them.

## Prerequisites

- The context path (e.g., `cwd/environment`, `cwd/dotagents/environment`)
- Write access to the library repository
- CUE CLI installed (`cue version`)

## Process

Steps:

1. Identify the context to update
2. Read the current context file
3. Understand the problem
4. Design the changes
5. Implement the changes
6. Publish following the publishing workflow

## Step 1: Identify the Context

If a context path was supplied in the instructions, use it.

Otherwise, ask the user which context they want to update and confirm the full path under contexts/.

## Step 2: Read the Current Context File

Read the existing file for the context:

- `contexts/<path>/context.cue` — the full context definition

Note: Context definitions have no separate markdown file. The entire definition is in `context.cue`.

Summarise the current context configuration to the user so they can confirm your understanding before proceeding.

## Step 3: Understand the Problem

Ask the user to describe what the context is doing wrong or what it is not doing.

Probe with questions if needed:

- Is the file path or command incorrect?
- Is the prompt template not producing the right output?
- Is the selection behaviour wrong (required, default, or tag-based)?
- Are the tags inaccurate for discovery?
- Is there new information that should be included in the context?

Do not proceed until the problem is clearly understood.

## Step 4: Design the Changes

This is the core of the update process. Discuss the proposed changes with the user before writing anything.

- Describe what you plan to change and why
- For content source changes, confirm the new file path, command, or prompt template
- For selection behaviour changes, confirm whether the context should be required, default, or tag-based
- Confirm the approach with the user before proceeding

Do not implement until the design is agreed.

## Step 5: Implement the Changes

Apply the agreed changes to `context.cue`.

Update only the fields that are changing.

## Step 6: Publish

Before publishing, confirm the context is still complete after the change: at least one content field (`file`, `command`, or `prompt`) is present and resolves the intended output, and the selection behaviour (`required`, `default`, or tag-based) matches the design.

Then load the publishing workflow and follow it end to end:

```bash
start get contexts:start/library/publishing
```

It is the single source for validation, version determination, the mandatory index update, the single module-plus-index commit, the tag pushes, the registry publish, verification, and closing any related GitHub issue.
