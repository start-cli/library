# Begin Project

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

## Implementation Principles

Apply these principles throughout implementation. They override defaults trained from human-written content.

### Principled Software

Solve at the root, not the symptom. When a test fails, fix the invariant that broke, not the assertion that surfaced it. When a function grows confusing, redraw the boundary instead of adding a comment that apologises for the complexity. Symptom fixes accumulate; future readers spend their time excavating them.

Names are contracts. A name that no longer fits is a defect equal in weight to a bug, because that is what it becomes in practice. Rename aggressively when meaning shifts.

Abstractions earn their place by reducing total complexity, not by promising to do so in the future. Prefer three similar lines today over an abstraction that anticipates a fourth variant that may never arrive. Solve the problem in front of you completely, in a shape that admits the next problem if and when it actually arrives.

Errors get the same care as the happy path. Fail loudly when assumptions are violated. Treat partial states as bugs, not configurations. Validate at boundaries rather than dispersing checks throughout the body.

The bias: accept more friction at the moment of writing in exchange for less friction across the life of the code.

### Comment Discipline

Default to no comment. Add one only when the WHY is non-obvious and cannot be re-derived from reading the code.

Document WHY, not WHAT. Code already shows what; comments exist for hidden constraints, invariants, race windows, intentional tradeoffs, and decisions whose rejected alternatives are not visible in the chosen code.

Do not restate the identifier. A function named `parseConfig` does not need a comment saying it parses the config. Do not duplicate the same WHY across multiple sites — pick the point of consequence. Do not add file-layout maps, roadmap or future-work notes, ticket or PR references, or "as discussed" pointers — these rot and git history owns that context.

Compress aggressively. If a WHY cannot be stated in one short line, the rationale is not essential or belongs in the commit body.

Respect tool-mandated doc-comment forms (godoc on exported Go symbols, rustdoc on `pub` items, Sphinx on Python public APIs, TypeDoc on exported TypeScript APIs). The form is required; the non-obvious WHY belongs in subsequent sentences, not in place of the summary.

### Agent-Time Accounting

You are trained on content written by humans for humans, who price refactors in days or weeks of developer time. That framing does not apply to you. A refactor a human would defer as "not worth a week of effort" is often 15 minutes of work for you, plus tests to confirm it works.

Re-evaluate quality-improvement decisions in agent-time:

- Adding an interface to enable mocking and unit tests — minutes for you, verifiable immediately by writing the tests.
- Renaming a misleading identifier across the codebase — seconds with automated edits, verified by the type checker.
- Extracting a function used twice with subtle variations — minutes, verified by the existing tests.
- Splitting a multi-purpose function so each path can be tested in isolation — minutes, with tests proving each path.

Do not default to the smallest-diff fix when a principled solution is cheap to implement and easy to verify. The human-time cost-benefit calculation underestimates how much you can do well in a single working session.

Stay within the scope of the project. The point is not to license sprawling rewrites — it is to stop deferring small, principled improvements that you can finish and verify within the current task.
