# Create Context

Create a new context definition in the library repository. This is an interactive process.

## Prerequisites

Confirm these values with the user before starting:

- Domain: The scope or subject area (e.g., `cwd`, `home`, `tools`)
- Specialisation: Optional narrowing segment (e.g., `dotai`)
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
6. Validate with CUE tools
7. Publish to CUE registry
8. Close related GitHub issue (if applicable)

## Step 1: Gather Prerequisites

Ask the user for:

1. Domain - kebab-case scope (e.g., `cwd`, `home`, `tools`)
2. Specialisation - optional narrowing segment (e.g., `dotai`). Omit if not needed
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
Specialisation: dotai
Noun: environment
Description: Project-specific environment context from .ai/environment.md
Selection: required, default
Content source: file .ai/environment.md
Tags: dotai, cwd, environment, project
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
module: "github.com/start-cli/library/contexts/<domain>/[specialisation/]<noun>@v0"
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

## Step 6: Validate with CUE Tools

Run validation from the context directory:

```bash
cd contexts/<domain>/[specialisation/]<noun>
cue mod tidy
cue vet context.cue
cue export context.cue
```

Expected results:

- `cue mod tidy` completes without errors
- `cue vet context.cue` produces no output (valid)
- `cue export context.cue` shows valid JSON with context definition

If validation fails:

- Check import paths match module.cue dependencies
- Verify package name is a valid Go identifier
- Ensure at least one content field (file, command, or prompt) is present
- Check Go template placeholder syntax (`{{.name}}`)

## Step 7: Publish to CUE Registry

After validation passes, update the index and publish everything in one commit.

Add an entry to `index/index.cue`:

```cue
"<domain>/[specialisation/]<noun>": {
    module:      "github.com/start-cli/library/contexts/<domain>/[specialisation/]<noun>@v0"
    version:     "v0.1.0"
    description: "<description>"
    tags: ["<domain>", "<tag1>", "<tag2>"]
}
```

Then commit, tag, and publish:

```bash
DOMAIN="<domain>"
SPEC=""  # or "<specialisation>/"
NOUN="<noun>"
VERSION="v0.1.0"

# Check latest remote index tag
git ls-remote --tags origin | grep "refs/tags/index/" | sort -t/ -k4 -V | tail -1
INDEX_VERSION="<next version>"

# Stage context files and index together — single commit
git add contexts/${DOMAIN}/${SPEC}${NOUN}/
git add index/index.cue
git commit -m "feat(contexts): add ${DOMAIN}/${SPEC}${NOUN} context"
git tag "contexts/${DOMAIN}/${SPEC}${NOUN}/${VERSION}"
git tag "index/${INDEX_VERSION}"
git push origin main
git push origin "contexts/${DOMAIN}/${SPEC}${NOUN}/${VERSION}"
git push origin "index/${INDEX_VERSION}"

cd contexts/${DOMAIN}/${SPEC}${NOUN}
cue mod publish ${VERSION}

cd <repo-root>/index
cue mod publish ${INDEX_VERSION}
```

Important: The CUE registry has tag immutability. Always check the latest remote tag with `git ls-remote` before tagging to avoid version conflicts.

## Step 8: Close Related GitHub Issue

If a GitHub issue exists for this context, close it:

```bash
gh issue close <issue-number> --repo start-cli/library --comment "Implemented as contexts/${DOMAIN}/${SPEC}${NOUN}@${VERSION}"
```
