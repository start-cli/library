# Naming Standards

Naming conventions for all module types in the start-cli library.

## Address Form

Every module has two related identifiers:

- The **name** is what appears within a category, structured as one or more slash-separated segments (e.g. `claude/interactive`).
- The **fully-qualified address** combines the category and the name with a colon: `category:name` (e.g. `agents:claude/interactive`). This is the canonical user-facing form for inputs and display.

This document describes the structure of the **name** for each category. Examples below are bare names; the fully-qualified address is the same string prefixed with `<category>:`.

## Common Rules

- Use kebab-case within path segments
- Use `/` to separate hierarchy levels within a name, not hyphens
- The name reads broad to specific, left to right
- Use only the segments needed for clarity
- Each segment of the name maps to a directory in the repository

## CUE Package Names

The `package` declaration inside a module's `.cue` file must be a valid CUE identifier (no hyphens). When the last path segment of the name contains hyphens, strip them in the package declaration.

| Last segment | Package declaration |
|--------------|---------------------|
| `interactive` | `package interactive` |
| `agents-md` | `package agentsmd` |
| `git-diff` | `package gitdiff` |
| `bypass-permissions` | `package bypasspermissions` |
| `non-interactive` | `package noninteractive` |

Strip hyphens; do not substitute underscores. This keeps one convention across the library.

Consumers importing a module whose package name does not match the last URL segment must use the `:pkgname` import suffix:

```cue
import (
    ctx "github.com/start-cli/library/contexts/cwd/agents-md@v1:agentsmd"
    tsk "github.com/start-cli/library/tasks/review/git-diff@v1:gitdiff"
)
```

This rule applies to new modules and to any republish at the next major version. The v1 modules `agents/{claude,copilot,gemini}/{bypass-permissions,non-interactive}` use the legacy underscore form (`bypass_permissions`, `non_interactive`); they remain on v1 for compatibility and convert to the stripped form at v2.

## Agents

Pattern: `tool/variant`

Every agent has an explicit variant name. No bare tool names as defaults.

| Segment | Required | Purpose |
|---------|----------|---------|
| tool | yes | The CLI tool name |
| variant | yes | The configuration variant |

Examples:

```
claude/interactive
claude/edit
claude/non-interactive
claude/unattended
gemini/interactive
gemini/bypass-permissions
```

## Roles

Pattern: `domain/[specialisation/]mode`

Mode is always the final segment: `agent`, `assistant`, or `teacher`.

| Segment | Required | Purpose |
|---------|----------|---------|
| domain | yes | The subject area or system |
| specialisation | no | Narrows the domain |
| mode | yes | The interaction mode |

Examples:

```
golang/agent
gitlab/pipeline/assistant
markdown/low-token/teacher
start/library/agent
```

Exception: file-based roles under `cwd/` and `home/` may use alternative final segments such as `default` or a filename reference (e.g., `cwd/role-md`, `cwd/dotai/default`) where no mode applies.

## Contexts

Pattern: `domain/[specialisation/]noun`

| Segment | Required | Purpose |
|---------|----------|---------|
| domain | yes | The subject area, system, or scope |
| specialisation | no | Narrows the domain |
| noun | yes | The thing being provided as context |

Examples:

```
cwd/agents-md
home/dotai/environment
tools/webctl/reference
```

## Tasks

Pattern: `[domain/][specialisation/][noun/]action`

The path reads as a natural instruction. Only the action segment is required.

| Segment | Required | Purpose |
|---------|----------|---------|
| domain | no | The system or tool. Omit when obvious from context |
| specialisation | no | Narrows the domain |
| noun | no | The thing being acted upon |
| action | yes | What you are doing |

Examples:

```
golang/debug
review/security
review/git-diff
jira/item/read
jira/item/research
confluence/doc/read
gitlab/pipeline/review
cwd/dotai/role/create
start/library/module/create
```

## Reserved Domains

`cwd` and `home` are reserved domain names used across all module types:

- `cwd` — the current working directory
- `home` — the user's home directory

Modules using these domains are published to the registry normally, but their content references local filesystem paths at runtime rather than bundled files. This makes them portable across machines while remaining tied to local context.

Examples:

```
cwd/agents-md           (context — reads AGENTS.md from the working directory)
cwd/readme/create       (task — operates on README.md in the working directory)
home/dotai/environment  (context — reads ~/.ai/environment.md)
```

## Tags

Tags are used for search and discovery. Follow these conventions:

- Use kebab-case
- Include the path segments as tags (domain, specialisation, noun)
- Add relevant technology or keyword terms beyond the path

Example for `jira/item/backlog/review`:

```
tags: ["jira", "item", "backlog", "review", "triage"]
```

## Action Verbs

Use `create` and `update` as a pair when the workflows are meaningfully different:
- `create` — the target does not exist yet
- `update` — the target exists and is being modified

Use `generate` when the task is analysis-driven and state-agnostic:
- The agent analyses context and produces or updates the target
- The workflow is the same whether the target exists or not

## Quick Reference

| Category | Pattern | Required Segments |
|----------|---------|-------------------|
| Agents | `tool/variant` | tool, variant |
| Roles | `domain/[specialisation/]mode` | domain, mode |
| Contexts | `domain/[specialisation/]noun` | domain, noun |
| Tasks | `[domain/][specialisation/][noun/]action` | action |
