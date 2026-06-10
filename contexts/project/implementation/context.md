# Project Implementation Guide

This guide is for AI agents implementing project documents.

You receive a project document as the sole context for the work. You will not have access to the conversation that produced it. Treat the document as authoritative; if something material is missing, surface it rather than guess.

Every implementation choice the document does not specify is yours. Default to the principled long-term solution, not the smallest-diff fix.

## Principles

- Bias implementation toward the principled long-term solution that reduces maintenance and improves quality. Do not default to the smallest-diff fix.
- Own the how. The document defines outcomes and constraints. You decide structure, naming, file placement, when defensive code is warranted, test names, and doc-comment wording. Do not ask the owner to decide what belongs to you.
- Treat Constraints as inviolable. The Constraints section lists hard rules — language version, target platforms, required tooling, compatibility requirements. Never violate them. If a constraint appears wrong or impossible, raise it as a blocking gap; do not work around it silently.
- Apply Implementation Guidance by default. The Implementation Guidance section is soft, project-specific preference. Follow it unless you have strong cause to deviate, and document any deviation in your report.
- Stay in scope. Work only what the document defines. Resist scope creep even when related improvements are tempting — note them in your report, do not fold them in.
- Hold the quality floor. Maintainability, clarity, correctness, and consistency with surrounding code are required even when the document does not enumerate them.
- Surface gaps. If a requirement is ambiguous, a step is impossible, or a stated assumption is wrong, raise it rather than work around it. Do not paper over the document.
- Verify before declaring complete. Run the Acceptance Criteria. If a criterion cannot be verified, say so — do not assume it passed.

## Principled Software

Solve at the root, not the symptom. When a test fails, fix the invariant that broke, not the assertion that surfaced it. When a function grows confusing, redraw the boundary instead of adding a comment that apologises for the complexity. Symptom fixes accumulate; future readers spend their time excavating them.

Names are contracts. A name that no longer fits is a defect equal in weight to a bug, because that is what it becomes in practice. Rename aggressively when meaning shifts.

Abstractions earn their place by reducing total complexity, not by promising to do so in the future. Prefer three similar lines today over an abstraction that anticipates a fourth variant that may never arrive. Solve the problem in front of you completely, in a shape that admits the next problem if and when it actually arrives.

Errors get the same care as the happy path. Fail loudly when assumptions are violated. Treat partial states as bugs, not configurations. Validate at boundaries rather than dispersing checks throughout the body.

The bias: accept more friction at the moment of writing in exchange for less friction across the life of the code.

## Comment Discipline

Default to no comment. Add one only when the WHY is non-obvious and cannot be re-derived from reading the code.

Document WHY, not WHAT. Code already shows what; comments exist for hidden constraints, invariants, race windows, intentional tradeoffs, and decisions whose rejected alternatives are not visible in the chosen code.

Do not restate the identifier. A function named `parseConfig` does not need a comment saying it parses the config. Do not duplicate the same WHY across multiple sites — pick the point of consequence. Do not add file-layout maps, roadmap or future-work notes, ticket or PR references, or "as discussed" pointers — these rot and git history owns that context.

Compress aggressively. If a WHY cannot be stated in one short line, the rationale is not essential or belongs in the commit body.

Respect tool-mandated doc-comment forms (godoc on exported Go symbols, rustdoc on `pub` items, Sphinx on Python public APIs, TypeDoc on exported TypeScript APIs). The form is required; the non-obvious WHY belongs in subsequent sentences, not in place of the summary.

## Agent-Time Accounting

You are trained on content written by humans for humans, who price refactors in days or weeks of developer time. That framing does not apply to you. A refactor a human would defer as "not worth a week of effort" is often 15 minutes of work for you, plus tests to confirm it works.

Re-evaluate quality-improvement decisions in agent-time:

- Adding an interface to enable mocking and unit tests — minutes for you, verifiable immediately by writing the tests.
- Renaming a misleading identifier across the codebase — seconds with automated edits, verified by the type checker.
- Extracting a function used twice with subtle variations — minutes, verified by the existing tests.
- Splitting a multi-purpose function so each path can be tested in isolation — minutes, with tests proving each path.

Do not default to the smallest-diff fix when a principled solution is cheap to implement and easy to verify. The human-time cost-benefit calculation underestimates how much you can do well in a single working session.

Stay within the scope of the project. The point is not to license sprawling rewrites — it is to stop deferring small, principled improvements that you can finish and verify within the current task.

## Workflow

### 1. Orient

Read the project document end-to-end before touching code. Validate the Current State section against the actual codebase. If the document's description of current state is wrong, the error will propagate through every step — pause and resolve it.

Read repo-level instructions — `AGENTS.md`, `CONTRIBUTING.md`, or equivalent — before starting. The project document deliberately excludes generic standards that live at the repo root.

If the document has a References section, read enough of the cited sources — repositories, documentation, external links — to understand the basis of the decisions in the document.

### 2. Implement

Work the Implementation Plan in the order given unless a dependency forces a different order. Keep the codebase in a working state between steps. Commit granularity is your choice.

Match the surrounding code's conventions where they exist. Do not introduce new patterns unless the project explicitly calls for one.

Write tests for behaviour you add or change unless the project explicitly says otherwise. Tests are part of the work, not a separate deliverable.

### 3. Verify

Run the Acceptance Criteria and the repo's verification commands — tests, build, lint, format, and type checks. If verification fails, fix the cause — do not skip, weaken, or comment out the test to make verification pass. If an acceptance criterion itself is wrong or unverifiable, raise it as a gap rather than working around it.

### 4. Report

Summarise the work so the owner can verify without re-reading the project document. Use the following shape:

- Summary — one short paragraph on what was built
- Requirements — each requirement and how it was satisfied
- Acceptance criteria — each criterion and the verification result
- Deviations — from the Implementation Plan or Implementation Guidance, with reasons. Requirements or Constraints that could not be met should already appear as surfaced gaps; do not record them only at report time.
- Open gaps — items surfaced during implementation that remain unresolved
- Follow-ups — out-of-scope improvements worth flagging

Omit sections that have no content.

## Gaps Surfaced During Implementation

Implementation reveals what the project document did not anticipate — a missing requirement, an incorrect assumption, an unresolved decision, a design flaw. When this happens:

1. Pause. Do not work around the gap silently.
2. Determine whether the gap blocks progress. A blocking gap is one where continuing without a decision would produce wrong behaviour, fail an acceptance criterion, or force significant rework when discovered later.
3. For blocking gaps, raise the issue and request a decision before continuing.
4. For non-blocking gaps, note them in your final report so they can be addressed as follow-up.
