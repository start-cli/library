# Create Context

Create a new context definition in the library repository. This is an interactive process.

## Prerequisites

Confirm these values with the user before starting:

- Domain: The scope or subject area (e.g., `cwd`, `home`, `tools`)
- Specialisation: Optional narrowing segment (e.g., `dotagents`)
- Noun: The thing being provided as context (e.g., `environment`, `agents-md`, `reference`)
- Description: Brief description of what context is provided
- Selection Behaviour: How the context is included (required, default, or tag-based)
- Content Source: How the context content is produced (file, command, prompt, or combination)

Requirements:

- Write access to the library repository
- CUE CLI installed (`cue version`)
- Understanding of the context's purpose and content source

## Context Creation Process

Steps:

1. Gather prerequisites from user
2. Design the context interactively
3. Create directory structure
4. Create context.cue with schema definition
5. Create cue.mod/module.cue with dependencies
6. Publish following the publishing workflow

## Step 1: Gather Prerequisites

Ask the user for:

1. Domain - kebab-case scope (e.g., `cwd`, `home`, `tools`)
2. Specialisation - optional narrowing segment (e.g., `dotagents`). Omit if not needed
3. Noun - the thing being provided (e.g., `environment`, `project`, `reference`)
4. Description - one-line summary of the context
5. Selection behaviour:
   - `required: true` - always included in every command
   - `default: true` - included when running plain `start` without flags
   - Neither - only included when matched by tag via `--context <tag>`
6. Content source - one or more of:
   - File path (static content)
   - Shell command (dynamic content)
   - Prompt template (combining file and/or command output)
7. Tags - kebab-case keywords for discovery and tag-based selection

The context path follows the naming standard: `domain/[specialisation/]noun`

Example values:

```
Domain: cwd
Specialisation: dotagents
Noun: environment
Description: Project-specific environment context from .agents/environment.md
Selection: required, default
Content source: file .agents/environment.md
Tags: dotagents, cwd, environment, project
```

## Step 2: Design the Context

Before creating any files, discuss and agree on the following with the user:

- Domain, specialisation, and noun — confirm the path follows naming conventions
- Content source — confirm whether to use a file, command, prompt, or combination
- Selection behaviour — confirm whether the context should be required, default, or tag-based only
- Tags — confirm keywords for discovery and tag-based selection

Do not proceed to file creation until the design is agreed.

## Step 3: Create Directory Structure

Create the context directory with cue.mod:

```bash
DOMAIN="<domain>"
SPEC=""  # or "<specialisation>/"
NOUN="<noun>"

mkdir -p contexts/${DOMAIN}/${SPEC}${NOUN}/cue.mod
```

Expected structure:

```
contexts/<domain>/[specialisation/]<noun>/
├── cue.mod/
│   └── module.cue
└── context.cue
```

Note: Contexts do not have a separate markdown file. Content is sourced at runtime via file paths, commands, or inline prompts defined in `context.cue`.

## Step 4: Create context.cue

Create the context schema definition file.

### Schema Fields

Contexts use the UTD (Unified Template Design) pattern for content sourcing, plus selection fields.

Selection fields:

| Field | Type | Purpose |
|-------|------|---------|
| required | bool | Always included in every command |
| default | bool | Included when running plain `start` |

UTD content fields (at least one required):

| Field | Type | Purpose |
|-------|------|---------|
| file | string | Path to a file. Provides `{{.file}}` and `{{.file_contents}}` |
| command | string | Shell command. Provides `{{.command}}` and `{{.command_output}}` |
| prompt | string | Go template combining placeholders into final output |

UTD configuration fields:

| Field | Type | Purpose |
|-------|------|---------|
| shell | string | Override default shell for command execution |
| timeout | int | Command timeout in seconds (1-3600) |

Common fields:

| Field | Type | Purpose |
|-------|------|---------|
| description | string | Brief description of the context |
| tags | list | Kebab-case keywords for discovery and selection |

### UTD Resolution Priority

When multiple content fields are set, resolution follows: prompt > file > command

- If only `file` is set, the file contents are returned directly
- If only `command` is set, the command output is returned directly
- If `prompt` is set, it is rendered as a Go template with access to `{{.file}}`, `{{.file_contents}}`, `{{.command}}`, and `{{.command_output}}`

### Template Placeholders

| Placeholder | Source | Purpose |
|-------------|--------|---------|
| `{{.file}}` | file field | The file path value |
| `{{.file_contents}}` | file field | Content read from the file |
| `{{.command}}` | command field | The command string |
| `{{.command_output}}` | command field | Output from running the command |
| `{{.datetime}}` | system | Current ISO 8601 date and time |

### Context Definition Templates

File-only context:

```cue
package <noun>

import "github.com/start-cli/library/schemas@v1"

context: schemas.#Context & {
	description: "<description>"
	tags: ["<domain>", "<tag1>", "<tag2>"]
	file: "<file-path>"
	prompt: """
		{{.file_contents}}
		"""
}
```

Command-only context:

```cue
package <noun>

import "github.com/start-cli/library/schemas@v1"

context: schemas.#Context & {
	description: "<description>"
	tags: ["<domain>", "<tag1>", "<tag2>"]
	command: "<shell-command>"
	prompt: """
		{{.command_output}}
		"""
}
```

Combined file and command context:

```cue
package <noun>

import "github.com/start-cli/library/schemas@v1"

context: schemas.#Context & {
	description: "<description>"
	tags: ["<domain>", "<tag1>", "<tag2>"]
	required: true
	default:  true
	file:    "<file-path>"
	command: "<shell-command>"
	prompt: """
		{{.file_contents}}

		Repository: {{.command_output}}
		"""
}
```

Notes:

- Package name must match the noun directory name (convert hyphens to valid Go identifier)
- The `context:` key is always literal `context` (the map key in the index provides the friendly name)
- Use `@module/` prefix for files bundled with the module
- File paths without `@module/` are resolved relative to the user's working directory at runtime

## Step 5: Create cue.mod/module.cue

Create the module definition:

```cue
module: "github.com/start-cli/library/contexts/<domain>/[specialisation/]<noun>@v1"
language: {
	version: "v0.16.0"
}
source: {
	kind: "git"
}
deps: {
	"github.com/start-cli/library/schemas@v1": {
		v: "v1.0.0"
	}
}
```

Contexts only depend on the schemas module.

## Step 6: Publish

Before publishing, confirm the context is complete: at least one content field (`file`, `command`, or `prompt`) is present and resolves the intended output, and the selection behaviour (`required`, `default`, or tag-based) matches the design.

Then load the publishing workflow and follow it end to end:

```bash
start get contexts:start/library/publishing
```

It is the single source for validation, version determination, the mandatory index update, the single module-plus-index commit, the tag pushes, the registry publish, verification, and closing any related GitHub issue. This is a create, so the module starts at v1.0.0.
