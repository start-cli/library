# Project Document Review

Interactive review of a project document before implementation begins. Finds design flaws, missing requirements, incorrect assumptions, and owner decisions that would force rework if discovered mid-implementation, then walks through each one and integrates the resolution into the project content.

Goal: catch issues that would force rework if discovered mid-implementation. Routine implementation judgement — naming, defensive code, local refactors — stays with the implementer.

Finding no new issues is a valid outcome. If the project document is complete and prior reviews have surfaced the real concerns, say so rather than invent findings to justify the run.

## Prerequisites

- A project document describing the work
- A repository with the codebase the project will touch

## Workflow

### Phase 1: Review

1. Find the project document. Look for clues in:
   - `AGENTS.md` — check for any reference to a current or active project
   - Common filenames at the repo root: `project.md`, `spec.md`, `ROADMAP.md`
   - Agent directories: `.ai/`, `.agents/`, `.claude/`, `.cursor/`, `.gemini/`, or similar
   - Documentation folders: `docs/`

   The project may be described as "active", "current", "in progress", "working on", or similar terms. If multiple candidates are found, ask the user to confirm. If none are found, ask the user where it is located.
2. Read the project document thoroughly.
3. Run the Size and Coherence Check (below). If it fires, skip to Phase 4 and declare Split the project.
4. Analyse the repository:
   - Validate the stated current state against the actual codebase
   - Check whether the proposed approach covers all stated requirements
   - Research external facts only when the project's approach turns on them — a specific dependency version, an API behaviour, or a platform capability. Generic dependency scans produce noise over repeated runs
5. Identify concerns that meet the Goal bar — issues that would force rework, cause incorrect behaviour, or leave a critical requirement unmet. Apply the Articulation Test and Regret Filter (see Reviewer Guidance) before listing each one.
6. Produce a structured report of findings using the Report Format (below) and present it inline. No disk writes.
7. Display the Top-level Prompt (see Commands).

### Size and Coherence Check

Signals that a project is too broad for a single implementation pass:

- Multiple independent outcomes that could ship separately
- Distinct code areas with no shared integration
- A refactor or sub-feature nested inside the parent with its own requirements, scope, and acceptance criteria
- Implementation Plan steps that partition cleanly with a natural handoff

If these signals fire, the review short-circuits. Finer issues found against a project that is about to be split will mostly go stale.

### Phase 2: Remediation

Apply safe items immediately, without prompting. Safe items are anything that does not touch application code:

- Tests — add, remove, or change
- Comments — add, remove, or change
- Documentation — add, remove, or change, excluding the project document itself

State what was applied for each safe item. Safe items do not count toward `M`.

Let `M` be the count of remaining actionable findings (everything not auto-applied above). Walk them one at a time. For each finding:

1. Re-read the relevant context — the project document and any referenced code — and critically re-evaluate the finding. The original may have been wrong, or rendered obsolete by an earlier fix. If the finding no longer holds, say so and revise or withdraw it before presenting.
2. Present the finding using the Per-item Template (below) with `n` as the position in the walk and `M` as the total. `M` excludes safe items applied above.
3. Display the Per-item Prompt (see Commands) and pause for an explicit decision. Never assume blanket approval from an earlier response. A `fix` on one finding does not authorise the next. If a response is ambiguous, ask which finding it applies to.

Per-item command semantics. Outcomes are tracked in-session — they are not written to disk at the moment of decision. They surface in the Phase 4 summary table and in the Remediation Summary if `save` is invoked.

- `fix` — apply the resolution to the project document, fully integrating it so the underlying issue is covered by the new content. Do not leave an Issues Discovered section; resolved items become polished project content. Track as `Fixed`. Briefly confirm what was done.
- `skip` — acknowledge and move on. Track as `Skipped`.
- `project` — spin the finding out as a standalone follow-up file (see Project File Format below). Track as `Project: <filename>`. Move to the next finding without offering an inline fix.
- `save` — see Save (below).

Remediation guidance:

- Bias recommendations toward the principled long-term solution that reduces maintenance and improves quality. Do not default to the smallest-diff resolution.
- Apply minimal, targeted edits to integrate the resolution. Refactor surrounding text only when required to make the resolution land cleanly.
- If a fix would be too large or risky to apply inline, recommend `project` to spin it out rather than attempting it inline.

### Phase 3: Satisfaction Pass

After all findings have been processed, re-read the project document with fresh eyes. Surface any new issues the edits themselves introduced — internal inconsistencies, gaps created by removed content, contradictions with sections that were not touched.

- Walk new findings using the same per-item flow from Phase 2
- This pass is lightweight — catch regressions introduced by the fixes, not run a full second review

### Phase 4: Wrap-up

1. Declare the outcome:
   - Ready to implement — no blocking issues remain
   - Issues to resolve — blocking issues remain; list them by number and title
   - Split the project — the document is too broad for a single implementation pass; summarise the seam

   An issue blocks implementation if proceeding without resolving it would force significant rework, cause incorrect behaviour, or leave a critical requirement unmet.
2. Print a summary table of all findings and their outcomes (see Remediation Summary in the Report Format).
3. Prompt the user once: type `save` to write the final report. Any other reply skips the save.

## Reviewer Guidance

- Trust the implementer — routine judgement on naming, defensive code, local refactors, and style stays with them
- Goal bar — flag a finding only if leaving it unresolved would force significant rework, cause incorrect behaviour, or leave a critical requirement unmet
- Articulation Test — if you cannot articulate what goes wrong when an item is left unresolved, it does not belong in the list
- Regret Filter — before finalising a finding, ask: would I regret not flagging this after implementation lands? If not, drop it
- Permission to find nothing — a late-run review that produces no findings is evidence the document is complete. Inventing findings to justify the run destroys the signal
- Recommendations target the principled long-term solution. Do not default to the minimal-diff resolution

## Issue Categories

| Category | Use when |
|----------|----------|
| decision | The owner needs to choose between valid alternatives |
| design | A flaw, weakness, or missing element in the design or architecture |
| gap | A requirement, step, or detail that is missing from the project document |
| risk | A potential problem that may not occur but should be acknowledged |
| dependency | An external dependency with version, compatibility, or availability concerns |

## Per-item Template

This template is a suggestion. Keep details succinct; expand only when the finding genuinely warrants it.

```
### Finding n of M: <short title>

Category: <decision | design | gap | risk | dependency>
Location: <file:line, or section heading if relevant>

Issue
<what the issue is and why it matters in context>

Options
<succinct options when alternatives are useful; omit if the resolution is obvious>

Recommendation
<which option, with a brief why focused on the principled long-term solution>

Action: awaiting decision (fix / skip / project)
```

For decisions, the Options block lists the alternatives the owner is choosing between. For other categories, include an Options block only when alternatives clarify the choice — otherwise lead with the Recommendation.

## Report Format

Structure the inline review report as follows:

```
## Project Document Review

Project: <path to project document>
Intent: <one sentence on what the project sets out to do>
Findings: <count by category, e.g. 1 decision, 2 design, 1 gap>
Safe items applied: <count, with a brief list, or "None">

## Findings

1. <Title> (<category>)

   <2–4 sentences on what the issue is and why it matters.>

   Options
   <succinct options when alternatives are useful; omit if the resolution is obvious>

   Recommendation: <which option, one or two sentences on why this is the principled fit>

## Assessment

<overall assessment of the project document, noting strengths and weaknesses>
```

When the report is saved after remediation begins, append the section below. Outcome values:

- `Fixed` — the resolution was applied to the project document
- `Skipped` — the user declined the fix
- `Project: <filename>` — spun out as a standalone follow-up
- `Pending` — `save` was invoked before the finding had been processed

```
## Remediation Summary

| # | Category | Finding | Outcome |
|---|----------|---------|---------|
| 1 | design | Brief description | Fixed |
| 2 | decision | Brief description | Skipped |
| 3 | gap | Brief description | Project: 01-project-add-rate-limiting.md |
| 4 | risk | Brief description | Pending |
```

## Project File Format

When `project` is selected during remediation, write a standalone file at the repository root named `NN-project-<slug>.md` where:

- `NN` starts at `01` and increments based on existing files matching the pattern
- `<slug>` is the short title lowercased and hyphenated (e.g. "Race condition in token refresh" becomes `race-condition-in-token-refresh`)

The file must be fully self-contained so a new AI agent session can pick it up with no extra context. Include only the sections below that apply — right-size the document to the scope of the finding.

```
# <title>

Source: project-doc-review on YYYY-MM-DD
Category: <decision | design | gap | risk | dependency>
Location: <file:line, or section heading>

## Goal

One to three sentences on what is being built or changed and why. Focus on outcome and motivation, not tasks.

## Scope

What is in scope; what is explicitly out of scope.

## Current State

Relevant existing state — files, configuration, and the finding itself — enough that the implementer can read the requirements with understanding.

## Requirements

Numbered, clear, verifiable deliverables. State what must be produced, not how.

## Implementation Plan

Ordered steps at a level that gives direction without prescribing code. Snippets are acceptable to clarify non-obvious integration. Omit if the requirements are self-explanatory.

## Constraints

Hard rules: language version, target platforms, required tooling, compatibility requirements. Items that cannot be violated without breaking the project.

## Acceptance Criteria

Observable, verifiable outcomes that signal completion. Project-specific only — do not list universals like "build passes" or "tests pass".
```

Writing guidelines:

- Define outcomes and constraints, not keystrokes. The implementing agent owns implementation details
- Be explicit and complete — do not reference the conversation that produced the finding
- Code snippets are acceptable for clarification; full implementations are not
- Use direct language: "do X", not "consider doing X"

## Save

When `save` is invoked at any phase:

1. Discover the next available filename: `.start/reviews/YYYY-MM-DD-project-doc-review-NN.md` where `YYYY-MM-DD` is today's date and `NN` starts at `01`, incrementing based on existing files matching the date and slug
2. Write the current report. If remediation has started, include the Remediation Summary section with current outcomes. Findings not yet processed are recorded as `Pending`
3. Confirm the filename written

## Commands

### Top-level Prompt

Display verbatim at the end of Phase 1:

```
- continue — walk through the findings
- save — write the report to .start/reviews/ and stop
```

### Per-item Prompt

Display verbatim after presenting each finding:

```
- fix — apply the resolution to the project document
- skip — record and move on
- project — spin this out as a standalone follow-up
- save — write the review-so-far to .start/reviews/ and stop
```
