# Update Agent

Update an existing agent definition in the library repository. This is primarily a design and discussion process — understanding what the agent definition is doing wrong or not doing, and agreeing on the changes before implementing them.

## Prerequisites

- The agent path (e.g., `claude/interactive`, `gemini/non-interactive`)
- Write access to the library repository
- CUE CLI installed (`cue version`)

## Process

Steps:

1. Identify the agent to update
2. Read the current agent file
3. Understand the problem
4. Design the changes
5. Implement the changes
6. Publish following the publishing workflow

## Step 1: Identify the Agent

If an agent path was supplied in the instructions, use it.

Otherwise, ask the user which agent they want to update and confirm the full path under agents/.

## Step 2: Read the Current Agent File

Read the existing file for the agent:

- `agents/<tool>/<variant>/agent.cue` — the full agent definition

Note: Agent definitions have no markdown file. The entire definition is in `agent.cue`.

Summarise the current agent configuration to the user so they can confirm your understanding before proceeding.

## Step 3: Understand the Problem

Ask the user to describe what the agent is doing wrong or what it is not doing.

Probe with questions if needed:

- Is the command template incorrect or missing flags?
- Are the model identifiers outdated?
- Is the role injection approach wrong for the target tool?
- Is the binary name incorrect for auto-detection?
- Is the description or tags inaccurate?

Do not proceed until the problem is clearly understood.

## Step 4: Design the Changes

This is the core of the update process. Discuss the proposed changes with the user before writing anything.

- Describe what you plan to change and why
- For command template changes, confirm the exact flag syntax with the user
- For model changes, confirm the full model identifiers
- Confirm the approach with the user before proceeding

Do not implement until the design is agreed.

## Step 5: Implement the Changes

Apply the agreed changes to `agent.cue`.

Update only the fields that are changing.

## Step 6: Publish

Before publishing, confirm the agent definition is still complete after the change: `command` retains the placeholders the tool needs, `bin` is set for auto-detection, and any `default_model` names a key in `models`.

Then load the publishing workflow and follow it end to end:

```bash
start get contexts:start/library/publishing
```

It is the single source for validation, version determination, the mandatory index update, the single module-plus-index commit, the tag pushes, the registry publish, verification, and closing any related GitHub issue.
