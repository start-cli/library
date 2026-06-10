# Begin Project

Load the current or active project document and implement it.

## Process

### Step 1: Find the Project Document

Locate the current, in progress, or active project document. Look for clues in:

- `AGENTS.md` — check for any reference to a current or active project
- Common filenames at the repo root: `project.md`, `spec.md`, `ROADMAP.md`
- Agent directories: `.agents/`, `.claude/`, `.cursor/`, `.gemini/`, or others
- Documentation folders: `docs/`

The project may be described as "active", "current", "in progress", "working on", or similar terms.

If multiple candidates are found, ask the user to confirm which one to start.

If no project document is found, ask the user where it is located.

### Step 2: Implement

Run the following command to load the implementation guide and follow it:

```bash
start get project/implementation
```

The guide defines the full implementation workflow — Orient, Implement, Verify, Report — and how to surface gaps discovered mid-implementation. Orient against the located project document, then work its Implementation Plan through that workflow, asking the user for input only when genuinely blocked.
