# Project: Module Reuse Field and Centralised Publishing Workflow

## Goal

Make module publishing reliable and defined in one place, and make module-to-module runtime references first-class. The canonical publish workflow now lives as the reusable context module `contexts/start/library/publishing`. Today the publish procedure is still copied into eight module-authoring tasks and has already drifted; the recurring failures are forgetting to update the index, splitting the index into a separate commit, and pushing a tag that already exists (which the immutable CUE registry then rejects). Cross-module references — one module calling another via `start get` — are invisible, buried in prose. This project adds the schema metadata that surfaces those references, routes the eight tasks at the single workflow, and removes the duplicated publish steps.

## Scope

In scope:

- Add an optional `uses` field to the shared `#Base` schema for declaring fully-qualified module references.
- Refactor the eight `tasks/start/module/{agent,role,context,task}/{create,update}` tasks to delegate their validate, publish, and issue-close tail to the publishing context via `start get`, and to declare that reference in `uses`.
- Adopt Scoped Commits (https://scopedcommits.com) for the publish workflow and record it as a repository convention.
- Add a brief versioning convention (minor-default, pointing to the publishing context as canonical) and a rule that recursive module references must be fully-qualified colon-form addresses, both to AGENTS.md.
- Fix the three existing bare `start get` references and declare them via `uses`.

Out of scope:

- Authoring the publishing context module. It already exists at `contexts/start/library/publishing`; this project consumes it.
- CLI support for the `uses` field — parsing, preservation on install, and doctor validation. That is the partner project in the start repo (`start/03-module-uses-field-support.md`). The library may publish `uses` ahead of CLI support: the CLI ignores unknown optional fields, so nothing breaks in the interim; the field is simply not yet preserved or validated.
- Any schema change other than the additive `uses` field.
- Module content unrelated to the validate, publish, and issue-close tail.

## Current State

Schemas live in `schemas/`. `#Base` (`schemas/base.cue`) carries `description`, `tags`, and `origin`, and is embedded by `#Agent`, `#Role`, `#Task`, and `#Context`. `#UTD` carries content mechanics (`file`, `command`, `prompt`, `shell`, `timeout`). The schemas module is published to the registry and imported as `schemas@v1`; confirm its current published version from the remote before bumping.

The canonical publish workflow already exists as the context module `contexts/start/library/publishing` (validated, registry-shaped like its sibling `contexts/start/library/naming`). It defines the full procedure — version determination from the remote, tag-collision preflight, mandatory index update, single module-plus-index commit, explicit tag pushes, registry publish, the `start update` then `start doctor validate --force` verification, and the versioning policy. The refactored tasks in this project reference it; this project does not author it.

The eight module tasks under `tasks/start/module/` each end with the same three steps — Validate, Publish, Close Related GitHub Issue — parameterised only by category and path. That tail is roughly 25 duplicated lines per task. It has drifted:

- `agent/update`, `context/update`, and `task/update` look up the next module version with `... | sort -t/ -k<n> -V | tail -1`, where `<n>` is a literal unresolved placeholder. As written these do not run.
- `role/update` uses the correct path-depth-agnostic form: `git ls-remote --tags origin "refs/tags/roles/<path>/*" | sed 's|.*/||' | sort -V | tail -1`.
- `task/create` looks up the module version from local tags (`git tag -l`) rather than the remote.
- `role/create` pushes tags with `git push origin --tags` (pushes all local tags) where the others push each tag explicitly.
- `task/create` carries extra "Quick Reference" and "Template Files" sections the others do not.
- The update tasks instruct "Determine the next patch version", which contradicts the versioning policy this project records.
- Issue-close comment wording differs across tasks ("Implemented as ...", "Fixed in ...", one hardcoding `@v1.0.0`).

Three modules already perform module-to-module reuse and establish the pattern this project formalises, but use bare (not colon-form) references:

- `tasks/cwd/project/begin/task.md` runs `start get project/implementation`.
- `tasks/cwd/project/create/task.md` runs `start get project/writing`.
- `tasks/start/module/role/update/task.md` runs `start get start/module/role/create`.

Neither declares the reference anywhere structured. No CUE dependency is involved — these are runtime content fetches, not CUE imports, so they must not be added to `cue.mod/module.cue` `deps`.

AGENTS.md documents repository structure, code style, the colon-form address scheme, module patterns, validation, and index updates. It does not document a publish workflow, a versioning policy, a commit convention, or a rule for recursive references.

## References

- https://scopedcommits.com — the commit-message convention being adopted. Format `<scope>: <description>`; multiple scopes allowed comma-separated; no `feat`/`fix` type prefix.
- https://semver.org — the basis of the versioning policy.
- `contexts/start/library/publishing/context.md` — the canonical publish workflow the tasks will reference, and the canonical source of the versioning policy that AGENTS.md points to.
- `start/03-module-uses-field-support.md` — the partner project in the start repo that makes the CLI parse, preserve, and validate the `uses` field.
- `contexts/project/implementation/context.md` — the implementation guide the implementer also follows.

## Requirements

1. Add an optional `uses` field to `#Base` in `schemas/base.cue`. It is a list of fully-qualified colon-form module addresses (`category:path`, where category is one of `agents`, `roles`, `contexts`, `tasks`). The constraint must reject bare names (no colon) and unknown categories. It declares the other library modules a module pulls in at runtime via `start get`. Being on `#Base`, all four module types inherit it; agents will not populate it.

2. Refactor the eight `tasks/start/module/*/{create,update}` tasks: remove the inline Validate-tail duplication for publish and issue-close, replacing it with a single instruction to load and follow `start get contexts:start/library/publishing`. Do not retain a per-task `cue vet`/`cue export` block — the publishing context's step 1 owns the generic validate gate (and its Roles section owns the multi-mode case), so re-creating it per task would reintroduce the duplication this project removes. A task may keep only an authoring-completeness check the publish gate cannot perform — that the category's content is finished, such as an agent having its `bin` set or a role having every intended mode authored — and delegates all `cue vet`, `cue export`, and publish steps to the context. Each refactored task declares `uses: ["contexts:start/library/publishing"]` in its `task.cue`. Because `#Task` is a closed CUE definition, a task validated against the schemas version it currently pins (`v1.0.0`) rejects the new `uses` field; before `cue vet` will accept the declaration, bump each refactored task's `schemas@v1` dependency in `cue.mod/module.cue` to the minor published in step 1. `cue mod tidy` will not do this on its own — it keeps the recorded minimal version — so set it explicitly (for example `cue mod get github.com/start-cli/library/schemas@v1.<minor>`). Remove the drift artifacts listed in Current State (the broken `-k<n>` lookups, the local-tag lookup, `git push origin --tags`, the `task/create` quick-reference and template-file cruft, the "next patch version" wording, and the divergent issue-close wording) — they are superseded by the single source.

3. The index-update step is delegated to the publishing context along with the rest of the publish tail; its step 4 already owns the index-entry guidance (copy an existing entry in the same category as a template, agent entries include `bin`, a role contributes one entry per mode). Remove the tasks' re-documentation of the index-entry shape entirely, with no per-task replacement — do not reinstate a copy-an-entry instruction in any task. Before deleting, confirm the publishing context's step 4 covers the copy-an-entry, `bin`, and per-mode guidance so nothing is lost.

4. Update the three existing reuse sites to fully-qualified colon form and declare them: `tasks/cwd/project/begin` references `contexts:project/implementation`; `tasks/cwd/project/create` references `contexts:project/writing`; `tasks/start/module/role/update` references `tasks:start/module/role/create` (in addition to the publishing context). Update the prose `start get` calls and add the corresponding `uses` lists. These sites also pin `schemas@v1.0.0`, so bump their `schemas@v1` dependency to the step 1 minor for the same closed-definition reason as the refactored tasks.

5. Add to AGENTS.md:
   - The rule that recursive module references inside published module content must be fully-qualified colon-form addresses, and must be declared in the module's `uses` field. Place near the existing Address Scheme section.
   - A brief versioning convention, not a second copy of the policy: state that versioning follows SemVer with a minor bump as the default, and name `contexts/start/library/publishing` as the canonical source for the detailed policy (minor/patch/major criteria, index-bump rule). Do not restate the full policy text in AGENTS.md; the publishing context owns it, and duplicating it here reintroduces the drift this project removes.
   - Scoped Commits as the repository commit convention, with AGENTS.md as the canonical home since it governs every commit, not only publishes: `<scope>: <description>`, scope is the module path or area, multiple scopes comma-separated, no `feat`/`fix` type prefix. Note that the publish workflow's module-plus-index commit is the canonical multi-scope case.
   - A one-line pointer to the publishing workflow: load `start get contexts:start/library/publishing`.

## Constraints

- CUE language pin `v0.16.0` in every `cue.mod/module.cue`.
- Schemas define pure constraints without defaults. The `uses` field is optional and additive; it must not break validation of any existing module. Adding it is a backwards-compatible change, so the schemas module takes a minor bump (determine the current published version from the remote and bump the minor).
- Kebab-case identifiers; package name matches the deepest directory segment.
- Do not add the publishing context to any task's `cue.mod` `deps`. It is a runtime `start get` reference, not a CUE import. The only thing recording it is the `uses` field.
- Markdown for agent documents: no bold, italic, horizontal rules, or emojis; headings to `###` maximum; single blank lines between sections.

## Implementation Plan

1. Add the `uses` field to `schemas/base.cue` with the colon-form constraint. Before publishing, prove the constraint locally against real addresses, not toy stand-ins: the deepest addresses this project actually writes — `uses: ["contexts:start/library/publishing"]` and `uses: ["tasks:start/module/role/create"]` (both depth 3) — must validate; a kebab-case address such as `uses: ["agents:claude/bypass-permissions"]` must also validate, even though this project does not write it, because hyphenated path segments are pervasive across the library and the regex is about to become immutable, so a segment pattern of `[a-z]+` that wrongly rejects them must be caught now; and the negatives `uses: ["project/implementation"]` (bare, no colon) and an unknown category must fail. The registry publish is irreversible, so a too-strict regex caught only when the tasks are validated in step 2 would spend `schemas/<version>` for nothing; the path-depth-agnostic, hyphen-tolerant constraint has to be exercised against the deepest and the kebab-case address while the tag is still free. Then publish the schemas module at the next minor version following the publishing workflow, with one exception: the schemas module is not index-tracked, so the index-specific parts of the workflow do not apply. Skip step 4 (update the index) and the index portions of steps 5 to 7 — the index in the commit, the `index/<version>` tag, and the index `cue mod publish`. Commit only the schemas change, push and publish only the `schemas/<version>` tag, and still run steps 1 to 3, the schemas-only commit, the step 8 verify, and the versioning policy.

2. Refactor the eight module tasks (Requirements 2 and 3): replace each publish tail with the `start get contexts:start/library/publishing` delegation (retaining only the authoring-completeness check Requirement 2 permits, not a per-task validate block), add the `uses` declaration, bump the task's `schemas@v1` dependency to the minor published in step 1 so the closed `#Task` definition accepts `uses`, and delete the drift artifacts. Keep each task's create- or update-specific design steps intact. Convert one task end to end — including the dependency bump — and confirm `cue vet` passes and the result matches the publishing context before converting the rest.

3. Update the three existing reuse sites to colon form, add their `uses` declarations, and bump their `schemas@v1` dependency to the step 1 minor (Requirement 4).

4. Update AGENTS.md (Requirement 5).

5. Republish every module changed in steps 2 to 4 at its appropriate next version using the publishing context, and update the index in the same commits.

## Implementation Guidance

- The publishing context already exists; the task refactor targets it. Treat it as the source of truth for the publish steps — do not re-describe them in the tasks, delegate to it.
- Only the publish tail of each task changes. Leave the create- and update-specific design and authoring steps intact.

## Acceptance Criteria

- `cue vet` passes for modules declaring `uses: ["contexts:project/implementation"]`, the depth-3 `uses: ["contexts:start/library/publishing"]`, and the kebab-case `uses: ["agents:claude/bypass-permissions"]`, and fails for a bare entry such as `uses: ["project/implementation"]` or an unknown category.
- Each of the eight `tasks/start/module/*/{create,update}` tasks contains no inline tag/publish commands, contains a `start get contexts:start/library/publishing` instruction, and declares `uses: ["contexts:start/library/publishing"]` in its `task.cue`.
- No task in `tasks/start/module/` contains the string `-k<n>`, `git push origin --tags`, or a `git tag -l`-based module version lookup.
- `tasks/cwd/project/begin`, `tasks/cwd/project/create`, and `tasks/start/module/role/update` use colon-form `start get` references and declare them in `uses`.
- AGENTS.md contains: the fully-qualified-reference rule, a brief versioning convention that points to `contexts/start/library/publishing` as canonical (not a full restatement of the policy), the Scoped Commits convention, and the publishing-workflow pointer.
