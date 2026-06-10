# Create Project Document

Create a new project document following the project writing guide.

## Process

### Step 1: Check for an Existing Active Project

Before creating a new project, check whether there is already a current or active project in progress.

Look for clues in:

- `AGENTS.md` — check for any reference to a current or active project
- Common filenames at the repo root: `project.md`, `spec.md`, `ROADMAP.md`, other markdown or document files
- Agent directories: `.agents/`, `.claude/`, `.cursor/`, `.gemini/`, or others
- Documentation folders: `docs/`

If an active project is found, inform the user and confirm they want to create a new one before continuing.

### Step 2: Load the Writing Guide

Run the following command to load the project writing guide, which defines the canonical structure, sections, formatting, and principles for project documents:

```bash
start get project/writing
```

The guide is the single source of truth for how a project document is written. Follow it for the rest of this task.

### Step 3: Gather Requirements

The writing guide defines the document's sections. Gather the inputs only the user can provide, and investigate the rest from the repository.

Ask the user about:

- Goal — what the project builds or changes, and why
- Scope — what is in and explicitly out
- Requirements — the concrete deliverables
- Constraints — hard rules (language version, platforms, tooling, compatibility, standards)
- Acceptance criteria — observable, verifiable signals of completion
- Implementation guidance — any project-specific preferences worth recording

Investigate rather than ask:

- Current State — read the relevant existing files, configuration, and dependencies
- References — record any sources consulted while drafting
- Implementation Plan — draft the ordered steps from the requirements and current state

Right-size: omit any optional section that does not apply.

### Step 4: Write the Project Document

Write the document following the structure, formatting, and principles defined by the writing guide loaded in Step 2.

File placement:

- If project documents using `NN-<stub>.md` numbering already exist in the repo, continue the sequence — name the new file with the next number.
- If no project documents exist, name it `project.md`.
- Place it in the repository root unless an extra instruction specifies a different location.

### Step 5: Update AGENTS.md

If there is a project reference in `AGENTS.md`, update it with the new project document.
