# Create Project Document

Create a new project document following established conventions.

## Process

Steps:

1. Check for an existing active project
2. Determine the next project number
3. Gather requirements interactively
4. Write the project document
5. Update the project index

## Step 1: Check for an Existing Active Project

Before creating a new project, check whether there is already a current or active project in progress.

Look for clues in:

- `AGENTS.md` — check for any reference to a current or active project
- Common filenames at the repo root: `project.md`, `spec.md`, `ROADMAP.md`, other markdown or document files
- Agent directories: `.agents/`, `.claude/`, `.cursor/`, `.gemini/`, or others
- Documentation folders: `docs/`

If an active project is found, inform the user and confirm they want to create a new one before continuing.

## Step 2: Determine the Next Project Number

Check for existing project documents to determine the next number:

- Look in the locations identified in Step 1
- If projects use a numbered format (e.g., `01`, `02`), use the next number in sequence
- If no numbered projects exist, start with `01`

## Step 3: Gather Requirements

Ask the user about:

- Project title and category
- Overview: what the project accomplishes and why it exists
- Goals: specific, measurable outcomes
- Scope: what is included and excluded
- Success criteria: how completion is measured
- Deliverables: concrete outputs

Optional sections to ask about if relevant:

- Dependencies on other projects
- Technical approach
- Research areas
- Decision points requiring owner input

## Step 4: Write the Project Document

Create the project file using this structure:

```
# NN: Title

- Status: Pending
- Started:
- Completed:

## Overview

Brief description of what this project accomplishes and why.

## Goals

1. First goal
2. Second goal

## Scope

In Scope:
- Item

Out of Scope:
- Item

## Success Criteria

- Measurable outcome
- Testable condition

## Deliverables

- Concrete output
```

Add optional sections as needed based on gathered requirements.

File naming: `NN-title.md` — lowercase kebab-case, placed in the same directory as other project documents, or in the repository root if no convention is established.

Writing rules:

- Do not use bold or italic formatting
- Use section headers and lists for structure
- Make success criteria measurable and testable
- Keep goals specific and achievable
- Define clear scope boundaries

## Step 5: Update AGENTS.md

If there is a project reference in `AGENTS.md`, update it with the new project document.
