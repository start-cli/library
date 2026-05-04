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
- Common filenames at the repo root: `project.md`, `spec.md`, `ROADMAP.md`
- Agent directories: `.ai/`, `.agents/`, `.claude/`, `.cursor/`, `.gemini/`, or others
- Documentation folders: `docs/`

If an active project is found, inform the user and confirm they want to create a new one before continuing.

## Step 2: Determine the Next Project Number

Check for existing project documents to determine the next number:

- Look in the locations identified in Step 1
- If projects use a numbered format (e.g., `p-001`, `p-002`), use the next number in sequence
- If no numbered projects exist, start with `p-001`
- If no numbering convention is found, omit the number and use a descriptive name only

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
# P-NNN: Title

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

File naming: `p-NNN-category-title.md` — lowercase kebab-case, placed in the same directory as other project documents, or `.ai/projects/` if no convention is established.

Writing rules:

- Do not use bold or italic formatting
- Use section headers and lists for structure
- Make success criteria measurable and testable
- Keep goals specific and achievable
- Define clear scope boundaries

## Step 5: Update the Project Index

If a project index exists (e.g., `.ai/projects/README.md`), add the new project entry. If no index exists, ask the user whether to create one.

Update `AGENTS.md` to point to the new project document as the active project.
