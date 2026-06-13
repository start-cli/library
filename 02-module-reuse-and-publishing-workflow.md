# Project: Module Reuse Field and Centralised Publishing Workflow

## Goal

Make module publishing reliable and defined in one place, and make module-to-module runtime references first-class. The canonical publish workflow now lives as the reusable context module `contexts/start/library/publishing`. Today the publish procedure is still copied into eight module-authoring tasks and has already drifted; the recurring failures are forgetting to update the index, splitting the index into a separate commit, and pushing a tag that already exists (which the immutable CUE registry then rejects). Cross-module references — one module calling another via `start get` — are invisible, buried in prose. This project adds the schema metadata that surfaces those references, routes the eight tasks at the single workflow, and removes the duplicated publish steps.

## Scope

In scope:

- Add an optional `uses` field to the shared `#Base` schema for declaring fully-qualified module references.
- Refactor the eight `tasks/start/module/{agent,role,context,task}/{create,update}` tasks to delegate their validate, publish, and issue-close tail to the publishing context via `start get`, and to declare that reference in `uses`.
- Adopt Scoped Commits (https://scopedcommits.com) for the publish workflow and record it as a repository convention.
- Add a versioning policy (minor-default) and a rule that recursive module references must be fully-qualified colon-form addresses, both to AGENTS.md.
- Fix the two existing bare `start get` references and declare them via `uses`.

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

Two modules already perform module-to-module reuse and establish the pattern this project formalises, but use bare (not colon-form) references:

- `tasks/cwd/project/begin/task.md` runs `start get project/implementation`.
- `tasks/start/module/role/update/task.md` runs `start get start/module/role/create`.

Neither declares the reference anywhere structured. No CUE dependency is involved — these are runtime content fetches, not CUE imports, so they must not be added to `cue.mod/module.cue` `deps`.

AGENTS.md documents repository structure, code style, the colon-form address scheme, module patterns, validation, and index updates. It does not document a publish workflow, a versioning policy, a commit convention, or a rule for recursive references.

## References

- https://scopedcommits.com — the commit-message convention being adopted. Format `<scope>: <description>`; multiple scopes allowed comma-separated; no `feat`/`fix` type prefix.
- https://semver.org — the basis of the versioning policy.
- `contexts/start/library/publishing/context.md` — the canonical publish workflow the tasks will reference; the versioning policy recorded in AGENTS.md must match it.
- `start/03-module-uses-field-support.md` — the partner project in the start repo that makes the CLI parse, preserve, and validate the `uses` field.
- `contexts/project/implementation/context.md` — the implementation guide the implementer also follows.

## Requirements

1. Add an optional `uses` field to `#Base` in `schemas/base.cue`. It is a list of fully-qualified colon-form module addresses (`category:path`, where category is one of `agents`, `roles`, `contexts`, `tasks`). The constraint must reject bare names (no colon) and unknown categories. It declares the other library modules a module pulls in at runtime via `start get`. Being on `#Base`, all four module types inherit it; agents will not populate it.

2. Refactor the eight `tasks/start/module/*/{create,update}` tasks: remove the inline Validate-tail duplication for publish and issue-close, replacing it with module-specific validation (the files unique to that category) followed by a single instruction to load and follow `start get contexts:start/library/publishing`. Each refactored task declares `uses: ["contexts:start/library/publishing"]` in its `task.cue`. Remove the drift artifacts listed in Current State (the broken `-k<n>` lookups, the local-tag lookup, `git push --tags`, the `task/create` quick-reference and template-file cruft, the "next patch version" wording, and the divergent issue-close wording) — they are superseded by the single source.

3. For the index-update step, instruct authors to copy an existing entry in the same category as a template rather than re-documenting the entry schema in prose (agent entries include `bin`; a role contributes one entry per mode). Remove any now-redundant re-documentation of the index-entry shape from the tasks.

4. Update the two existing reuse sites to fully-qualified colon form and declare them: `tasks/cwd/project/begin` references `contexts:project/implementation`; `tasks/start/module/role/update` references `tasks:start/module/role/create` (in addition to the publishing context). Update the prose `start get` calls and add the corresponding `uses` lists.

5. Add to AGENTS.md:
   - The rule that recursive module references inside published module content must be fully-qualified colon-form addresses, and must be declared in the module's `uses` field. Place near the existing Address Scheme section.
   - A versioning policy that matches `contexts/start/library/publishing`: default to a minor bump for additive or behavioural content changes (new guidance, new index entries, new optional fields); use patch only for trivial fixes (typos, formatting with no behavioural change); use major for breaking the contract (removing or renaming a field consumers rely on, changing `prompt` semantics). The index bump follows the same logic and is almost always minor.
   - Scoped Commits as the repository commit convention: `<scope>: <description>`, scope is the module path or area, multiple scopes comma-separated, no `feat`/`fix` type prefix. Note that the publish workflow's module-plus-index commit is the canonical multi-scope case.
   - A one-line pointer to the publishing workflow: load `start get contexts:start/library/publishing`.

## Constraints

- CUE language pin `v0.16.0` in every `cue.mod/module.cue`.
- Schemas define pure constraints without defaults. The `uses` field is optional and additive; it must not break validation of any existing module. Adding it is a backwards-compatible change, so the schemas module takes a minor bump (determine the current published version from the remote and bump the minor).
- Kebab-case identifiers; package name matches the deepest directory segment.
- Do not add the publishing context to any task's `cue.mod` `deps`. It is a runtime `start get` reference, not a CUE import. The only thing recording it is the `uses` field.
- Markdown for agent documents: no bold, italic, horizontal rules, or emojis; headings to `###` maximum; single blank lines between sections.

## Implementation Plan

1. Add the `uses` field to `schemas/base.cue` with the colon-form constraint. Validate the schema against the examples under `docs/examples/`. Publish the schemas module at the next minor version following the publishing workflow.

2. Refactor the eight module tasks (Requirements 2 and 3): replace each publish tail with category-specific validation plus the `start get contexts:start/library/publishing` delegation, add the `uses` declaration, and delete the drift artifacts. Keep each task's create- or update-specific design steps intact. Convert one task end to end and check it against the publishing context before converting the rest.

3. Update the two existing reuse sites to colon form and add their `uses` declarations (Requirement 4).

4. Update AGENTS.md (Requirement 5).

5. Republish every module changed in steps 2 to 4 at its appropriate next version using the publishing context, and update the index in the same commits.

## Implementation Guidance

- The publishing context already exists; the task refactor targets it. Treat it as the source of truth for the publish steps — do not re-describe them in the tasks, delegate to it.
- Only the publish tail of each task changes. Leave the create- and update-specific design and authoring steps intact.

## Acceptance Criteria

- `cue vet` passes for a module declaring `uses: ["contexts:project/implementation"]` and fails for a bare entry such as `uses: ["project/implementation"]` or an unknown category.
- Each of the eight `tasks/start/module/*/{create,update}` tasks contains no inline tag/publish commands, contains a `start get contexts:start/library/publishing` instruction, and declares `uses: ["contexts:start/library/publishing"]` in its `task.cue`.
- No task in `tasks/start/module/` contains the string `-k<n>`, `git push --tags`, or a `git tag -l`-based module version lookup.
- `tasks/cwd/project/begin` and `tasks/start/module/role/update` use colon-form `start get` references and declare them in `uses`.
- AGENTS.md contains: the fully-qualified-reference rule, the versioning policy, the Scoped Commits convention, and the publishing-workflow pointer.
