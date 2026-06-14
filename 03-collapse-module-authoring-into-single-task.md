# Project: Collapse Module-Authoring Tasks into a Single Author Task

## Goal

Replace the eight `tasks/start/module/{agent,role,context,task}/{create,update}` modules with one interactive `tasks/start/module/author` task that creates or updates any module type. Collapsing the eight near-duplicate tasks into one removes the create/update and per-category duplication, halves nothing by parts but reduces eight published modules and eight index entries to one, and routes every shared concern — naming, publishing — at the existing single-source contexts.

## Scope

In scope:

- Author one new module, `tasks/start/module/author`, that handles both operations (create, update) across all four categories (agent, role, context, task).
- Delegate naming decisions to `contexts:start/library/naming` and the publish/index/issue-close tail to `contexts:start/library/publishing`, both via runtime `start get` and both declared in the task's `uses` field.
- Carry the category-specific authoring knowledge (directory shapes, cue templates, the role Role Prompt Guide, context UTD fields) inline in the task, one section per category.
- Retire the eight `tasks/start/module/*/{create,update}` modules: remove their directories and their eight index entries, add the one `author` index entry.

Out of scope:

- The `uses` field itself. It is already published in `schemas@v1.1.0` and is consumed here as-is.
- Authoring or changing the `naming` and `publishing` contexts. They already exist and are consumed as-is.
- The AGENTS.md policy additions (versioning policy, Scoped Commits, recursive-reference rule, publishing pointer). They are already in AGENTS.md and this project relies on them. Requirement 8's one-line fix to the stale commit example at `AGENTS.md:166` is in scope and is the only AGENTS.md change this project makes.
- CLI support for `uses` (the partner project `start/03-module-uses-field-support.md`).

The eight tasks were already refactored in place (the publish tail now delegates to the publishing context and each declares `uses`). This project deletes them rather than refactoring further; the `tasks/start/module/role/update` module is removed along with the rest.

## Current State

The eight tasks live under `tasks/start/module/{agent,role,context,task}/{create,update}/`, each a published module with its own index entry. Every task is a `task.cue` (referencing the `roles/start/library/assistant` role, prompt `Read {{.file}}`), a `task.md`, and a `cue.mod/module.cue` depending on schemas and the role.

They share a five-part shape: gather prerequisites, design interactively, scaffold and write files, validate, publish. The validate/publish/issue-close tail already delegates to `contexts/start/library/publishing`, and each task declares `uses: ["contexts:start/library/publishing"]`; the create tasks still document naming inline. The create and update variants within a category differ only in "does the target exist yet" and the version origin (v1.0.0 vs a bump). The per-category differences are real but small:

- Agents: `tool/variant`; `agent.cue` only, no markdown; fields `command`, `bin`, `default_model`, `models`; depends on schemas only; never populates `uses`.
- Roles: `domain/[specialisation/]mode`; three modes (agent, assistant, teacher) authored together on create, only affected modes on update; `role.cue` plus `role.md` per mode; carries the Role Prompt Guide that shapes role.md content.
- Contexts: `domain/[specialisation/]noun`; `context.cue` only, no markdown; UTD content fields plus `required`/`default` selection.
- Tasks: `[domain/][specialisation/][noun/]action`; `task.cue` plus `task.md`; optional role reference; inline-vs-`Read {{.file}}` prompt choice.

The naming rules these tasks reference now live in `contexts/start/library/naming` (`context.md`), and the publish workflow in `contexts/start/library/publishing` (`context.md`). Both are registry-shaped published contexts. The naming context covers address form, leaf-only names, package-name derivation, per-category patterns, reserved domains, tags, and action verbs. The publishing context covers version determination from the remote, tag-collision preflight, the mandatory single module-plus-index commit, explicit tag pushes, registry publish, verification, and the versioning policy.

`#Base` (`schemas/base.cue`) carries `description`, `tags`, `origin`, and the optional `uses` field (a list of fully-qualified colon-form module addresses), published in `schemas@v1.1.0`. This project's task declares `uses`, which the published schema already accepts.

The repository root holds numbered project documents (`03-collapse-module-authoring-into-single-task.md`). Project documents are handed to a fresh-session implementer as sole context.

## References

- `contexts/start/library/naming/context.md` — the naming source of truth the author task delegates to.
- `contexts/start/library/publishing/context.md` — the publish workflow the author task delegates to.
- `contexts/project/writing/context.md` — the guide this document follows.
- The eight existing `tasks/start/module/*/{create,update}/task.md` files — the source material whose category-specific content is consolidated into the new task. In particular `tasks/.../role/create/task.md` carries the Role Prompt Guide to be preserved verbatim.

## Requirements

1. Create `tasks/start/module/author` as a single module: `task.cue`, `task.md`, `cue.mod/module.cue`. Package name `author`. Address `tasks:start/module/author`. It is the only module-authoring task; it handles create and update for all four categories.

2. `task.cue` references the `roles/start/library/assistant` role, uses the `Read {{.file}}` prompt form (the document is large), and declares both delegated contexts in `uses`:

   ```cue
   uses: [
   	"contexts:start/library/naming",
   	"contexts:start/library/publishing",
   ]
   ```

   `cue.mod/module.cue` depends only on schemas and the assistant role. The two `uses` entries are runtime `start get` references, not CUE imports; they must not appear in `deps`.

3. `task.md` determines two axes interactively before doing any work: operation (create or update) and category (agent, role, context, task). It infers them from the user's request where possible and asks otherwise.

4. `task.md` delegates naming to the naming context rather than re-documenting any naming rule. At the point path, package-name, or tag decisions are made, it instructs the agent to load and follow `start get contexts:start/library/naming`.

5. `task.md` describes the create and update workflows as distinct flows, with prose on how they differ. Create confirms the target does not exist, scaffolds, writes from a source or from scratch, and publishes at v1.0.0. Update confirms the target exists, reads current files and summarises them back, understands the problem, designs and applies changes touching only what changes, and publishes a version bump. Both flows preserve the design-before-writing discipline of the existing tasks. The existence confirmation is the authority on operation: the inferred operation from requirement 3 is a starting hypothesis, and when the confirmation contradicts it — a create finds the target already present, or an update finds it missing — the task pivots to the other flow within this same task, confirming the switch with the user. Because `author` is now the only module-authoring task, the flows never redirect the user to a separate create or update task and never hard-error on the mismatch; the old sibling-redirect preconditions are retired.

6. `task.md` carries one specifics section per category, each giving the files produced, the cue template(s), the cue.mod dependency shape, and category notes. The roles section preserves the Role Prompt Guide and the three-mode handling (all three on create, affected modes on update). The agents section notes `uses` stays empty for agents. No category section re-documents naming (requirement 4) or publishing (requirement 7).

7. `task.md` delegates the entire validate-adjacent publish tail — version determination, tag preflight, the single module-plus-index commit, tag pushes, registry publish, verification, and issue close — to the publishing context. After category-specific validation, it instructs the agent to load and follow `start get contexts:start/library/publishing`. It re-documents no tag, version, commit, or `gh issue close` command.

8. Retire the eight old modules in the same change that lands `author`: delete the `tasks/start/module/{agent,role,context,task}/{create,update}/` directories and remove their eight `index/index.cue` entries. Add the single `author` index entry. Replace the eight-item `### start/module/` list in `tasks/README.md` with a single `start/module/author` entry. Update the multi-scope commit example at `AGENTS.md:166`, which currently names the removed `start/module/agent/create`, to name this project's module (for example `start/module/author, index: ...`); `AGENTS.md` is in-repo documentation, so it is fixed here in the same change. The old modules' registry tags remain (immutable) but drop out of the index. The `start/module/context/create` example at `contexts/start/library/naming/context.md:155` now names a removed task; the naming context is a separately-published module and out of scope to change here, so leave it for a future naming-context revision. That revision should both swap the example for `start/module/author` and extend the Action Verbs section to bless a single module that handles both create and update, since `author` deliberately merges the create/update pair the current guidance describes as separate.

## Constraints

- The task declares `uses` and depends on the `uses` field in `schemas@v1.1.0`, which is already published. Resolve `schemas@v1` at a version that includes it.
- Do not add `contexts:start/library/naming` or `contexts:start/library/publishing` to `cue.mod` `deps`. They are runtime references recorded only in `uses`.
- CUE language pin `v0.16.0` in `cue.mod/module.cue`.
- Kebab-case identifiers; package name `author` matches the deepest path segment.
- Naming and publishing content must be delegated, not copied. The task may name what the delegated context covers but must not restate its rules or commands.
- Markdown for agent documents: no bold, italic, emojis, or horizontal rules; headings to `###` maximum; single blank lines between sections; tables and lists for structure.
- Follow the publishing context for the publish itself, including the single module-plus-index commit covering both the new `author` module and the eight retired index entries.

## Implementation Plan

1. Confirm `schemas@v1` resolves with the `uses` field (published in `schemas@v1.1.0`). The existing tasks already declare `uses`, so this is a quick sanity check rather than a gate.

2. Author `tasks/start/module/author/task.cue` and `cue.mod/module.cue` per requirement 2.

3. Write `tasks/start/module/author/task.md`:
   - Operation-and-category determination (requirement 3).
   - A naming step delegating to the naming context (requirement 4).
   - Create and update flows with their differences (requirement 5).
   - Four category specifics sections, consolidating the templates and notes from the existing eight tasks and preserving the Role Prompt Guide (requirement 6).
   - A validate step (per-category, per-mode for roles) followed by publish delegation to the publishing context (requirement 7).

4. Validate the new module from its directory (`cue mod tidy`, `cue vet task.cue`, `cue export task.cue`). Confirm a bare or unknown-category `uses` entry would fail and the colon-form entries pass.

5. Update `index/index.cue`: add the `author` entry, remove the eight old entries.

6. Delete the eight `tasks/start/module/{agent,role,context,task}/{create,update}/` directories and update the `### start/module/` list in `tasks/README.md` to the single `start/module/author` entry.

7. Publish following `contexts:start/library/publishing`: one module-plus-index commit covering the new module directory, the eight deleted directories, and `index/index.cue`; tag and publish `author` at v1.0.0 and the index at its next version.

## Implementation Guidance

- Convert the design by consolidating, not rewriting. The category specifics already exist across the eight task.md files; lift them into one document and remove only what naming and publishing now own.
- Verify each delegation against the live context content before finalising — read `contexts/start/library/naming/context.md` and `contexts/start/library/publishing/context.md` and ensure the task names what they cover without duplicating it. If something the old tasks did is missing from both contexts, fold it into the task's own flow rather than re-deriving the context's rules.
- The update flow for roles is the subtle one: it operates on only the affected modes, while create always produces all three. Keep that distinction explicit in the roles section.

## Acceptance Criteria

- `tasks/start/module/author` exists with `task.cue`, `task.md`, `cue.mod/module.cue`, package `author`, and validates with `cue vet`.
- `task.cue` declares `uses: ["contexts:start/library/naming", "contexts:start/library/publishing"]` and `cue.mod/module.cue` `deps` contains neither context.
- `task.md` contains a `start get contexts:start/library/naming` instruction and a `start get contexts:start/library/publishing` instruction, and contains no inline tag, version-lookup, commit, or `gh issue close` commands.
- `task.md` contains four category specifics sections and preserves the Role Prompt Guide.
- None of the eight `tasks/start/module/{agent,role,context,task}/{create,update}` directories remain, and `index/index.cue` contains the `author` entry and none of the eight old entries.
- `tasks/README.md` lists `start/module/author` and none of the eight removed tasks.
- The naming and publishing rules appear nowhere in `task.md` except as delegation pointers.
