# Start Project

Load context from the current or active project and begin implementation.

## Process

Steps:

1. Find the project document
2. Load context
3. Begin implementation

## Step 1: Find the Project Document

Locate the current, in progress, or active project document. Look for clues in:

- `AGENTS.md` — check for any reference to a current or active project
- Common filenames at the repo root: `project.md`, `spec.md`, `ROADMAP.md`
- Agent directories: `.ai/`, `.agents/`, `.claude/`, `.cursor/`, `.gemini/`, or others
- Documentation folders: `docs/`

The project may be described as "active", "current", "in progress", "working on", or similar terms.

If multiple candidates are found, ask the user to confirm which one to start.

If no project document is found, ask the user where it is located.

## Step 2: Load Context

With the project document located:

- Read the project document thoroughly
- Read relevant code files, documentation, and configuration referenced by the project
- If the document includes a Current State section, use it to understand what has already been done
- If the document includes Decision Points, check whether they have been resolved before proceeding — if unresolved blocking decisions exist, surface them to the user

## Step 3: Begin Implementation

With full context loaded, begin implementing the project. Work through the goals and deliverables defined in the project document, asking the user for input only when genuinely blocked.
