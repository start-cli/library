# Pre-commit Code Review

Interactive review of code changes from git diff output. Finds issues, walks through each one, and fixes them before commit.

This is not a general-purpose repository review. The diff output is the guide -- only review the changed code and its immediate context.

## Prerequisites

- A Git repository with code changes

## Workflow

### Phase 1: Review

1. Run git status to confirm we are in a Git repository and determine the state of changes (staged, unstaged, or both)
2. Determine the appropriate diff command:
   - `git diff` for unstaged only
   - `git diff --staged` for staged only
   - `git diff HEAD` for both
   - `git diff <default>..HEAD` for changes since a branch point
   - Follow user instructions if provided
3. Run the diff command and read the output to understand the scope and intent of the changes
4. For each changed file, read the full file and related files to understand surrounding context
5. Review the changes against all criteria below
6. Produce a structured report of findings and present it inline (do not save to disk yet)
7. Reserve the filename `.start/reviews/YYYY-MM-DD-pre-commit-NN.md` for any save during this session
   - Use today's date for `YYYY-MM-DD`
   - Increment `NN` based on existing files in `.start/reviews/` matching the date and type, starting at `01`
8. Prompt the user with two options:
   - Type `save` to write the report to the reserved filename and stop here
   - Type `continue` to proceed to remediation. The `save` command remains available during remediation

### Phase 2: Remediation

At any point, type `save` to write the report plus current remediation progress to the reserved filename from Phase 1 and exit. Findings not yet processed are recorded as `Pending` in the Remediation Summary.

If the report contains info-level findings, display them up front as a single table so the user has visibility before the fix/skip walk begins:

```
### Info-level Findings

| # | Category | Location | Note |
|---|----------|----------|------|
| 1 | Readability | src/foo.go:42 | Brief observation |
```

Info items are not part of the fix/skip walk -- they are recorded only.

Let `M` be the count of actionable findings (critical, high, medium, low). Walk them in severity order. For each finding, use this presentation template:

```
### Issue N of M: <short title>

Severity: <critical | high | medium | low>
Category: <e.g. Security, Correctness>
Location: <file:line>

Issue
<2-4 sentence description and why it matters in context>

Recommendation
<concrete proposed change, referencing specific code. If trade-offs exist, explain why this approach over alternatives>

Action: awaiting decision (fix / skip / project)
```

Per-finding flow:

1. Re-read the target code and related code carefully, then critically re-evaluate the recommendation. The original finding may have been wrong, or rendered obsolete by an earlier fix. If the recommendation no longer holds, say so and revise or withdraw it before presenting
2. Print the finding using the template above
3. If the fix is purely additive (new unit tests, or new or clarifying code comments), apply it immediately, update the printed Action to `Applied`, and briefly confirm what was done. Modifications to existing tests still pause for discussion -- they can mask regressions by relaxing assertions
4. Otherwise, pause for discussion. Wait for an explicit per-finding response before proceeding -- never assume blanket approval from an earlier response. A `fix` on one finding does not authorise the next. If a response is ambiguous, ask which finding it applies to. The user selects one of:
   - `fix`: apply the change, record as `Fixed`, and briefly confirm what was done
   - `skip`: acknowledge, record as `Skipped`, and move to the next finding
   - `project`: spin the finding out as a standalone follow-up file (see Project File Format below), record as `Project: <filename>`, and move to the next finding without offering an inline fix

Remediation guidance:

- Apply minimal, targeted fixes -- refactor surrounding code if required for the issue at hand
- If a fix would be too large or risky to apply inline, recommend the user select `project` to spin it out rather than attempting an inline fix
- Keep each fix focused on the issue being addressed and related code

### Phase 3: Post-fix Check

After all findings have been processed, do a focused re-check on only the code that was modified by fixes during Phase 2.

- Only examine the lines and immediate context touched by fixes, not a full re-review
- If new issues are found, walk through them using the same fix/skip/project flow from Phase 2
- This pass should be lightweight -- its purpose is to catch regressions introduced by the fixes themselves
- After fixes are applied, run any formatters or linters the project has configured on the touched files and address any new violations they surface

### Phase 4: Wrap-up

1. Print a summary table of all findings and their outcomes
2. If `save` was already invoked during this session, overwrite the reserved filename with the final report including the Remediation Summary section, then continue
3. Otherwise, prompt the user: type `save` to write the report to the reserved filename. Any other reply skips the save
4. Remind the user to review the changes before committing

## Reviewer Guidance

- The diff is your primary input -- stay focused on what changed
- Read surrounding code in changed files to understand context
- Distinguish between new issues introduced by the diff and pre-existing issues
- Flag pre-existing issues if discovered
- Ask clarifying questions when the intent of a change is unclear
- Reference the specific file and change from the diff in each finding
- Classify findings by severity (critical, high, medium, low, info):
  - Not every review category will produce findings at every severity level
  - Use the levels that fit rather than forcing findings into categories that do not apply
- Findings about multiple unrelated changes within a single commit are classified as `info`
- Write "None" for any severity level where no findings exist. Every section must be present in the report
- It is acceptable to find no issues. If the changes are well-implemented, say so. Do not manufacture findings to justify the review

## 1. Holistic Review

- Conceptual Integrity: Verifying the codebase feels written by one mind with consistent patterns rather than a patchwork of conflicting styles
- Repository Structure: Assessing if the file layout and directory organization are intuitive and self-explanatory
- Solution Fit: High-level verification that the implementation aligns with the repository's stated purpose and architectural manifest
- Tech Stack Coherence: Identifying library sprawl or conflicting tool choices that complicate the strategic technical direction
- Project Hygiene: Checking for the presence and consistency of top-level configuration, CI/CD health, and environment setup
- Codebase Atrophy: Detecting signs of large-scale rot, such as abandoned modules, ghost directories, or obsolete features
- Cognitive Profile: Assessing if the overall solution complexity is proportionate to the problem domain being solved

## 2. Security Review

- Authentication and Authorisation: Verifying the integrity of identity verification and the strict enforcement of access boundaries across all layers
- Input Validation and Sanitisation: Ensuring all untrusted data is validated and cleaned to prevent injection and manipulation attacks
- Secrets Management: Confirming that sensitive credentials and configuration data are handled via secure, externalized mechanisms
- Data Protection and Encryption: Assessing the safety of sensitive information at rest and in transit, including the prevention of data leakage in logs
- Cryptography Usage: Evaluating the implementation of cryptographic primitives to ensure the use of proven, industry-standard protocols
- Session Management: Reviewing the lifecycle and security properties of user sessions and tokens to prevent hijacking or unauthorized reuse
- API Security: Identifying risks in endpoint design, including improper resource exposure or excessive data return
- CORS and CSRF Protection: Verifying that cross-origin policies and request forgery protections are correctly configured
- Rate Limiting: Assessing the system's resilience against automated abuse, brute-force attempts, and resource exhaustion
- Secure Headers: Confirming the presence of security-related HTTP headers that harden the client-side execution environment
- Path Traversal: Ensuring that file and resource pathing logic cannot be manipulated to access restricted areas
- Deserialization Safety: Verifying that the conversion of data formats into objects does not introduce execution risks
- Privilege Escalation: Analyzing logic for flaws that could allow a user to perform actions beyond their intended permission level

## 3. Correctness Review

- Algorithm Correctness: Verifying that the logic produces the expected output for all valid inputs and maintains logical integrity
- Business Logic Accuracy: Ensuring the implementation faithfully represents the specified domain rules and stakeholder intentions
- State Transitions: Assessing how the system moves between states to ensure data remains consistent and the flow is logical
- Data Transformations: Evaluating the precision of data mapping and conversion logic to prevent loss of fidelity or unintended mutations
- Operator and Condition Correctness: Reviewing conditional branches, logical operators, and comparison logic for accuracy and exhaustive coverage
- Boundary and Off-by-one Errors: Identifying logic flaws that occur at the extreme limits of data ranges, loops, and collection indices
- Order of Operations: Verifying that the sequence of execution and precedence of operations yield the logically sound result
- Visual Fidelity (UI): Assessing whether the rendered output aligns with the design specifications across various viewports
- Responsive Behaviour (UI): Verifying that the interface adapts correctly to different screen sizes and platform constraints
- Interaction States: Reviewing the behavior and visual feedback of elements during user engagement

## 4. Architecture Review

- System Design and Layering: Ensuring clear separation of concerns where each layer has a distinct responsibility and avoids leaky abstractions
- Component Boundaries: Verifying that interactions between modules are well-defined and do not violate the principle of least knowledge
- Dependency Flow: Assessing the direction of dependencies to ensure high-level policy is protected from implementation details
- Modularity and Reusability: Identifying opportunities for abstraction that reduce coupling while avoiding premature generalization
- API Design and Contracts: Evaluating the stability and clarity of interfaces to ensure they are difficult to misuse
- Backwards Compatibility: Ensuring changes do not break existing integrations, data formats, or downstream expectations
- Configuration Management: Verifying that system behavior can be adjusted safely through structured configuration without code changes
- Rollout Strategy: Reviewing how features are exposed to allow for safe deployment and incremental validation
- Scalability and Extensibility: Assessing if the design accommodates growth in data volume or future requirements without requiring a rewrite
- Database Integrity: Verifying that schema changes maintain data consistency and handle migrations safely

## 5. Concurrency Review

- Race Conditions: Identifying logic where the outcome depends on the non-deterministic timing of execution across multiple threads
- Deadlocks and Livelocks: Ensuring that synchronization logic does not lead to states where the system is permanently stalled
- Thread Safety: Verifying that shared resources are accessed through safe mechanisms that prevent data corruption
- Shared State Management: Assessing the necessity of shared state and ensuring that mutable data is minimized
- Async Patterns: Evaluating the use of asynchronous primitives to ensure they are handled without blocking or unhandled failures
- Context and Cancellation: Verifying that operations respect cancellation signals and propagate execution context correctly
- Resource Pools: Assessing the management of thread pools or connection pools to prevent exhaustion

## 6. Standards Review

- Accessibility (WCAG/ARIA): Ensuring the implementation is usable by individuals with diverse needs and complies with established standards
- Internationalisation (i18n): Verifying that the code is prepared for localization, handling diverse languages and cultural formats
- Regulatory Compliance: Assessing adherence to legal and data privacy frameworks such as GDPR or HIPAA where applicable
- Industry Standards: Verifying compliance with domain-specific protocols relevant to the project's industry
- Organisational Standards: Ensuring the change aligns with internal engineering playbooks and agreed-upon conventions

## 7. Observability Review

- Logging Quality: Ensuring logs provide sufficient context and appropriate severity levels to facilitate incident response
- System Metrics: Verifying that critical performance and health indicators are instrumented for monitoring
- Product Analytics: Confirming that user interaction events are captured accurately to inform business decisions
- Distributed Tracing: Assessing the propagation of trace identifiers to allow for visualization of requests across services
- Structured Output: Verifying that telemetry data is emitted in a format that is easily parsed by analysis tools
- Health Checks: Ensuring the system exposes accurate readiness and liveness signals for orchestration

## 8. Performance Review

- Algorithmic Complexity: Identifying logic with sub-optimal complexity that could degrade as input size grows
- Memory Management: Assessing allocation patterns to minimize unnecessary pressure on the garbage collector or memory limits
- I/O Efficiency: Evaluating the frequency and size of network and disk operations to minimize latency
- Database Efficiency: Identifying N+1 query patterns or expensive join operations that impact system throughput
- Resource Lifecycles: Ensuring that connections, file handles, and other finite resources are closed promptly
- Caching Strategy: Identifying opportunities to reuse expensive computations while ensuring invalidation is sound
- Infrastructure Impact: Assessing whether the code introduces excessive compute or storage costs relative to its value

## 9. Error Handling Review

- Exception Strategy: Ensuring that errors are caught at the appropriate level and not swallowed without logging
- Error Propagation: Verifying that error context is preserved as it moves through the system to aid root cause analysis
- Graceful Degradation: Assessing how the system behaves when a dependency or non-critical component fails
- Edge Case Coverage: Identifying unhappy paths and unexpected inputs that could cause the system to crash
- Retry and Fallbacks: Evaluating the safety and back-off strategy of automatic retries to prevent worsening failures
- Fail-Fast vs Fail-Safe: Verifying that the system chooses the appropriate failure mode for the specific context

## 10. Testing Review

- Coverage Depth: Assessing whether tests verify the logic of the change across a representative range of scenarios
- Test Quality: Ensuring tests are readable, maintainable, and verify behavior rather than implementation details
- Production Testability: Identifying code structures that make automated testing difficult and suggesting refactors
- Test Isolation: Verifying that tests do not share state or depend on external environments
- Flakiness Prevention: Identifying tests that may fail intermittently due to timing or environmental factors
- Mocking and Stubbing: Evaluating the use of doubles to ensure they are realistic and do not mask actual integration issues

## 11. Readability Review

- Naming Intent: Verifying that names for variables, functions, and classes reveal their purpose and the reason for their existence
- Cognitive Complexity: Identifying logic that is too dense or requires excessive mental effort to parse
- Expressiveness: Assessing whether the code uses language features that clearly communicate the developer's intent
- Comment Utility: Ensuring comments are used to explain non-obvious decisions rather than restating the code
- Pattern Consistency: Verifying that the change follows established idioms within the codebase to reduce the learning curve
- Code Flow: Assessing the narrative of the code to ensure the most important logic is prominent

## 12. Dependency Review

- Justification: Evaluating whether a new dependency is necessary or if the problem could be solved with existing tools
- Maintenance and Health: Assessing the activity level, security history, and community support of external libraries
- License and Security: Verifying that the dependency's license is compatible and checking for known vulnerabilities
- Supply Chain Risk: Reviewing the impact of transitive dependencies and the stability of the package history
- Asset Impact: Evaluating the effect of the dependency on bundle sizes, startup times, or deployment complexity

## 13. Duplication Review

- Functional Duplication: Identifying similar logic performed in multiple places that should be centralized
- Pattern Redundancy: Recognizing repeated structural patterns that suggest a missing abstraction
- Boilerplate Reduction: Assessing if the change introduces repetitive code that could be simplified through better design

## 14. Documentation Review

- External Accuracy: Ensuring that the README, public API docs, and help guides reflect the actual state of the code
- Developer Onboarding: Verifying that instructions for building, testing, and running the code remain clear
- Decision Records: Ensuring that significant architectural shifts are documented for future context
- Change Transparency: Assessing if the changelog accurately describes the impact of the changes for users

## Report Format

Structure the review report as follows:

```
## Diff Review Summary

Scope: <number of files changed, insertions, deletions>
Intent: <brief description of what the changes accomplish>
Findings: {count per severity, e.g. 2 critical, 1 high, 3 medium, 1 low, 4 info}

## Critical Findings

<issues that must be fixed before merging, or "None">

## High Findings

<issues that should be fixed before merging, or "None">

## Medium Findings

<issues worth addressing but not blocking, or "None">

## Low Findings

<minor suggestions worth addressing, or "None">

## Info Findings

<observations recorded for awareness only, not part of the fix/skip walk, or "None">

## Assessment

<overall assessment of the changes, noting both strengths and weaknesses>
```

When the report is saved after remediation begins, append the following section. Outcome values are:

- `Fixed` -- the change was applied
- `Skipped` -- the user declined the fix
- `Project: <filename>` -- spun out as a standalone follow-up (see Project File Format below)
- `Pending` -- `save` was invoked before the finding had been processed

```
## Remediation Summary

| # | Severity | Finding | Outcome |
|---|----------|---------|---------|
| 1 | critical | Brief description | Fixed |
| 2 | high     | Brief description | Skipped |
| 3 | medium   | Brief description | Project: 01-project-race-condition-in-token-refresh.md |
| 4 | low      | Brief description | Pending |
```

## Project File Format

When `project` is selected during remediation, write a standalone file at the repository root named `NN-project-<slug>.md` where:

- `NN` starts at `01` and increments based on existing files matching the pattern
- `<title>` is the `<short title>` value from the presentation template used during remediation
- `<slug>` is `<title>` lowercased and hyphenated (e.g. "Race condition in token refresh" becomes `race-condition-in-token-refresh`)

The file must be fully self-contained so a new AI agent session can pick it up with no extra context. Include only the sections below that apply -- right-size the document to the scope of the finding.

```
# <title>

Source: pre-commit review on YYYY-MM-DD
Severity: <critical | high | medium | low>
Category: <e.g. Security, Correctness>
Location: <file:line>

## Goal

One to three sentences on what is being built or changed and why. Focus on outcome and motivation, not tasks.

## Scope

What is in scope; what is explicitly out of scope.

## Current State

Relevant existing state -- files, configuration, and the finding itself -- enough that the implementer can read the requirements with understanding.

## Requirements

Numbered, clear, verifiable deliverables. State what must be produced, not how.

## Implementation Plan

Ordered steps at a level that gives direction without prescribing code. Snippets are acceptable to clarify non-obvious integration. Omit if the requirements are self-explanatory.

## Constraints

Hard rules: language version, target platforms, required tooling, compatibility requirements. Items that cannot be violated without breaking the project.

## Acceptance Criteria

Observable, verifiable outcomes that signal completion. Project-specific only -- do not list universals like "build passes" or "tests pass".
```

Writing guidelines:

- Define outcomes and constraints, not keystrokes. The implementing agent owns implementation details
- Be explicit and complete -- do not reference the conversation that produced the finding
- Code snippets are acceptable for clarification; full implementations are not
- Use direct language: "do X", not "consider doing X"
