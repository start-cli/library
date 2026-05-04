# Project Review

Review the current or active project document to identify issues before implementation begins.

Goal: Catch design flaws, missing requirements, incorrect assumptions, and owner decisions that would force rework if discovered mid-implementation. Routine implementation judgement — naming, defensive code, local refactors — stays with the implementer.

Finding no new issues is a valid outcome. If the project document is complete and prior reviews have surfaced the real concerns, say so rather than invent findings to justify the run.

## Process

Steps:

1. Find the project document
2. Analyse the codebase and documentation
3. Research to validate the approach
4. Update the project document
5. Declare the outcome

## Step 1: Find the Project Document

Locate the current, in progress, or active project document. Look for clues in:

- `AGENTS.md` — check for any reference to a current or active project
- Common filenames at the repo root: `project.md`, `spec.md`, `ROADMAP.md`
- Agent directories: `.ai/`, `.agents/`, `.claude/`, `.cursor/`, `.gemini/`, or others
- Documentation folders: `docs/`

The project may be described as "active", "current", "in progress", "working on", or similar terms.

If multiple candidates are found, ask the user to confirm which one to review.

If no project document is found, ask the user where it is located.

## Step 2: Analyse the Codebase and Documentation

With the project document located, analyse the repository:

- Read the project document thoroughly
- Explore relevant code files and documentation
- Validate the project's stated current state against the actual codebase
- Check whether the proposed approach covers all stated requirements
- Identify concerns that meet the Goal bar — issues that would force rework, cause incorrect behaviour, or leave a critical requirement unmet

Routine implementation judgement stays with the implementer. Do not flag naming preferences, defensive nil-checks for unreachable cases, pre-existing inefficiencies the refactor preserves, or style choices.

### Size and Coherence

Assess whether the project describes one cohesive outcome or multiple. Signals that a project is too broad for a single implementation pass:

- Multiple independent outcomes that could ship separately
- Distinct code areas with no shared integration
- A refactor or sub-feature nested inside the parent with its own requirements, scope, and acceptance criteria
- Implementation Plan steps that partition cleanly with a natural handoff

If these signals fire, skip Step 3 and Step 4 and declare the Split the project outcome at Step 5. Finer issues found against a project that is about to be split will mostly go stale.

## Step 3: Research to Validate the Approach

Research only when the project's approach turns on a specific external fact — a particular dependency version, an API behaviour, a platform capability. Generic dependency scans produce noise over repeated reviews. Skip them unless the project depends on something specific.

When research is warranted:

- Check the specific version or API behaviour the approach relies on
- Review documentation for external services the project integrates with
- Identify known breaking changes or compatibility concerns relevant to the approach
- Validate technical assumptions the project explicitly makes

Stop researching once the approach is validated. Record only concerns that meet the Goal bar.

## Step 4: Update the Project Document

Based on the analysis:

- Ensure the document includes a Current State section with relevant codebase context
- Update the Issues Discovered section (or add one if it does not exist) with any issues meeting the Goal bar

Before finalising the list, re-read each item and ask: would I regret not flagging this after implementation lands? If not, remove it. This second-pass filter prevents accumulation of low-value items.

### Issues Discovered

The Issues Discovered section is the primary output of this review. List issues that would materially affect implementation. If you cannot articulate what goes wrong when an item is left unresolved, do not list it.

Each issue is numbered. Numbers stay stable for traceability — resolved items are amended in place, not moved to a separate section.

Each issue includes:

- A clear title
- A description of what the issue is and why it matters
- A category label: `decision`, `design`, `gap`, `risk`, or `dependency`
- For decisions, the options the owner must choose between. For other categories, a suggested resolution is optional — include it only when it clarifies the issue, not to justify the finding.

Category definitions:

| Category | Use when |
|----------|----------|
| decision | The owner needs to choose between valid alternatives |
| design | A flaw, weakness, or missing element in the design or architecture |
| gap | A requirement, step, or detail that is missing from the project document |
| risk | A potential problem that may not occur but should be acknowledged |
| dependency | An external dependency with version, compatibility, or availability concerns |

Open item format:

```
### Issues Discovered

1. No retry strategy for webhook delivery (design)

   The current design sends webhooks once with no retry on failure.
   Transient network errors would cause silent data loss.
   Suggested resolution: Add exponential backoff with a dead-letter queue.

2. Choice of queue backend (decision)

   The project references a message queue but does not specify which one.
   A. Redis Streams — simple, already in the stack.
   B. RabbitMQ — more features, new dependency.
   C. SQS — managed, adds AWS dependency.
```

## Step 5: Declare the Outcome

Conclude the review with one of three outcomes:

Ready to implement:

> The project is ready to implement. There are [N] unresolved issues, none of which block implementation. [Brief summary.]

Issues to resolve:

> The project has [N] unresolved issues that must be resolved before implementation can proceed. [List the blocking issues by number and title.]

Split the project:

> The project is too broad for a single implementation pass. Recommend splitting: [summary of the seam]. Continue review after the project is split.

An issue blocks implementation if proceeding without resolving it would force significant rework, cause incorrect behaviour, or leave a critical requirement unmet. All other issues are non-blocking.

If unresolved issues remain after declaring the outcome, display this message:

> Say "continue" to work through the unresolved issues one at a time.

The review is complete after declaring the outcome. The following section applies only if the user chooses to continue.

## Resolving Issues

If the user wants to work through the unresolved issues (e.g., "let's review", "continue", or similar), go through them one at a time. For each issue:

- Describe the issue in detail with relevant context from the codebase
- Recommend a solution with reasoning
- Wait for the user to decide what to do

When an issue is resolved, amend the item in place — do not move it, do not renumber, do not create a separate resolved section. Append the decision to the title line and add a Resolution line to the body.

Resolved item format:

```
1. No retry strategy for webhook delivery (design) — Resolved: accepted risk.

   The current design sends webhooks once with no retry on failure.
   Transient network errors would cause silent data loss.
   Resolution: Retry logic deferred to v2. Acceptable for initial release
   given low webhook volume.

2. Choice of queue backend (decision) — Resolved: Redis Streams.

   The project references a message queue but does not specify which one.
   Resolution: Redis Streams chosen — already in the stack, sufficient for
   current scale.
```
