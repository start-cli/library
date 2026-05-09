# start CLI Library

CUE-based module library for the start AI agent launcher CLI. Modules include agents, roles, contexts, and tasks, published to the CUE Central Registry under `github.com/start-cli/library`.

## Repository Structure

| Directory | Purpose |
| --- | --- |
| agents/ | AI CLI tool command templates |
| roles/ | System prompt and behaviour definitions |
| contexts/ | Environmental context definitions |
| tasks/ | Task instruction definitions |
| schemas/ | CUE schema definitions |
| index/ | Module discovery index |
| docs/ | Naming standards and authoring patterns |

## Code Style

CUE conventions:

- Modules are identified by index keys, not by `name` fields
- Use kebab-case for tags and identifiers
- Schemas define pure constraints without defaults
- Package names match the deepest directory segment (hyphens removed)
- Import schemas from `github.com/start-cli/library/schemas@v1`
- CUE language pin: `v0.16.0` in every `cue.mod/module.cue`

Markdown for agent documents:

- No bold, italic, horizontal rules, or emojis
- Use headings, code blocks, tables, and lists
- Keep heading depth at `###` maximum
- Single blank lines between sections
- Callout prefixes (Note:, Warning:) without bold

## Address Scheme

User-facing fully-qualified module addresses use the colon form `category:name`:

- `agents:claude/interactive`
- `roles:golang/assistant`
- `contexts:cwd/agents-md`
- `tasks:review/git-diff`

Bare names (`claude/interactive`) continue to work as cross-category lookups. CUE module paths (`github.com/start-cli/library/agents/claude/interactive@v0`) remain slash-based; the colon form applies to user-facing input and display only.

Index keys inside the index module are bare names within their category struct (`agents: { "claude/interactive": ... }`). The colon prefix is not encoded in keys.

## Module Patterns

UTD (Unified Template Design):

| Field | Purpose |
| --- | --- |
| file | Path to file (provides `{{.file}}`, `{{.file_contents}}`) |
| command | Shell command (provides `{{.command}}`, `{{.command_output}}`) |
| prompt | Go template with placeholders |

Resolution priority: prompt > file > command. At least one of the three must be present.

Common placeholders:

- `{{.file}}` - File path (local or temp)
- `{{.file_contents}}` - File contents (lazy, only read if referenced)
- `{{.command}}` - Command string
- `{{.command_output}}` - Command execution output (lazy, only executed if referenced)
- `{{.datetime}}` - Current timestamp in RFC3339 format
- `{{.instructions}}` - CLI argument passed to a task (empty otherwise)
- `{{.cwd}}` - Current working directory
- `{{.home}}` - User home directory
- `{{.user}}` - System username
- `{{.hostname}}` - Machine hostname
- `{{.os}}` - OS identifier (linux, darwin, windows)
- `{{.os_name}}` - OS/distro name
- `{{.shell}}` - Current shell basename
- `{{.git_branch}}` - Current git branch (empty if not in a repo)
- `{{.git_root}}` - Git repository root directory (empty if not in a repo)
- `{{.git_user}}` - Git user name
- `{{.git_email}}` - Git user email

Module file structure:

Each module contains a CUE definition file and `cue.mod/module.cue`. Modules carrying long-form prose also ship a markdown file referenced via `file: "@module/<name>.md"`.

```
tasks/review/git-diff/
  task.cue
  task.md
  cue.mod/
    module.cue
```

Index updates:

When adding a new module, register it in `index/index.cue`:

```cue
"category/name": {
    module:      "github.com/start-cli/library/<category>/<name>@v0"
    version:     "v0.1.0"
    description: "Brief description of the module"
    tags: ["relevant", "tags"]
}
```

## Validation

Schema validation from the schemas directory:

```bash
cd schemas
cue vet utd.cue task.cue ../docs/examples/task_example.cue
cue vet utd.cue role.cue ../docs/examples/role_example.cue
cue vet utd.cue context.cue ../docs/examples/context_example.cue
cue vet agent.cue ../docs/examples/agent_example.cue
cue vet index.cue ../docs/examples/index_example.cue
```

Module validation from a module directory (resolves `schemas@v1` from the registry):

```bash
cd agents/claude/interactive
cue mod tidy
cue vet ./...
```

Index validation (cue vet plus the non-TTY default-resolution contract for the agents map):

```bash
scripts/validate-index
```

## References

- Naming standards: docs/naming-standards.md
- Agent patterns: docs/agent-patterns.md
- Role patterns: docs/role-patterns.md
- Schema reference: schemas/README.md
- start CLI: https://github.com/start-cli/start
