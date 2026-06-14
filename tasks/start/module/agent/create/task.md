# Create Agent

Create a new agent definition in the library repository. This is an interactive process.

## Prerequisites

Confirm these values with the user before starting:

- Tool: The CLI tool name (e.g., `claude`, `gemini`, `aichat`)
- Variant: The configuration variant (e.g., `interactive`, `non-interactive`, `unattended`)
- Description: Brief description of the agent variant
- Binary: The executable name for auto-detection (usually same as tool name)
- Command Template: The shell command with placeholders
- Models: Optional model aliases and their full identifiers
- Source Content: Either:
  - An existing agent definition to adapt
  - A description of the agent's purpose (to create from scratch)

Requirements:

- Write access to the library repository
- CUE CLI installed (`cue version`)
- Understanding of the target CLI tool's flags and usage

## Agent Creation Process

Steps:

1. Gather prerequisites from user
2. Design the agent interactively
3. Create directory structure
4. Create agent.cue with schema definition
5. Create cue.mod/module.cue with dependencies
6. Publish following the publishing workflow

## Step 1: Gather Prerequisites

Ask the user for:

1. Tool name - the CLI tool (e.g., `claude`, `gemini`, `ollama`)
2. Variant name - kebab-case configuration variant (e.g., `interactive`, `bypass-permissions`, `edit`)
3. Description - one-line summary of the agent variant
4. Binary name - executable name for auto-detection and `{{.bin}}` placeholder
5. Command template - the shell command using placeholders
6. Default model - optional default model alias
7. Models - optional map of short aliases to full model identifiers

The agent path follows the naming standard: `tool/variant`

Example values:

```
Tool: claude
Variant: interactive
Description: Claude Code by Anthropic - agentic coding assistant
Binary: claude
Command: {{.bin}} --model {{.model}} --permission-mode default --append-system-prompt-file {{.role_file}} {{.prompt}}
Default model: sonnet
Models: haiku=claude-haiku-4-5-20251001, sonnet=claude-sonnet-4-6-20250514, opus=claude-opus-4-6-20250620
```

## Step 2: Design the Agent

Before creating any files, discuss and agree on the following with the user:

- Tool and variant — confirm the path follows naming conventions
- Command template — confirm the exact flags and placeholders needed
- Role injection approach — confirm how the target tool accepts a system prompt
- Models — confirm whether model aliases are needed and what they map to
- Binary name — confirm the executable name for auto-detection

Do not proceed to file creation until the design is agreed.

## Step 3: Create Directory Structure


Create the agent directory with cue.mod:

```bash
TOOL="<tool>"
VARIANT="<variant>"

mkdir -p agents/${TOOL}/${VARIANT}/cue.mod
```

Expected structure:

```
agents/<tool>/<variant>/
├── cue.mod/
│   └── module.cue
└── agent.cue
```

Note: Unlike roles and tasks, agents do not have a markdown file. The agent definition is entirely in `agent.cue`.

## Step 4: Create agent.cue

Create the agent schema definition file.

### Schema Fields

| Field | Required | Type | Purpose |
|-------|----------|------|---------|
| command | yes | string | Shell command template with placeholders |
| description | yes | string | Brief description of the agent |
| tags | no | list | Kebab-case keywords for discovery |
| bin | no | string | Binary name for auto-detection |
| default_model | no | string | Default model alias (must be a key in models) |
| models | no | map | Short alias to full model identifier mapping |

### Command Template Placeholders

| Placeholder | Purpose |
|-------------|---------|
| `{{.bin}}` | Replaced with the `bin` field value |
| `{{.model}}` | Replaced with the resolved model identifier |
| `{{.prompt}}` | Replaced with the task prompt content |
| `{{.role}}` | Replaced with the role prompt content (inline) |
| `{{.role_file}}` | Replaced with a path to a temp file containing the role |

### Role Injection Patterns

Different CLI tools accept roles differently. Common patterns:

- Command-line flag: `--append-system-prompt-file {{.role_file}}`
- Environment variable: `GEMINI_SYSTEM_MD={{.role_file}}`
- Inline argument: `--system {{.role}}`

Check the target tool's documentation to determine the correct approach.

### Agent Definition Template

With models:

```cue
package <variant>

import "github.com/start-cli/library/schemas@v1"

agent: schemas.#Agent & {
	bin:         "<binary-name>"
	command:     "<command-template>"
	description: "<description>"
	default_model: "<default-alias>"
	models: {
		"<alias>": "<full-model-id>"
		"<alias>": "<full-model-id>"
	}
	tags: ["<tool>", "<tag1>", "<tag2>"]
}
```

Without models (simple agent):

```cue
package <variant>

import "github.com/start-cli/library/schemas@v1"

agent: schemas.#Agent & {
	bin:         "<binary-name>"
	command:     "<command-template>"
	description: "<description>"
	tags: ["<tool>", "<tag1>", "<tag2>"]
}
```

Notes:

- Package name must match the variant directory name (convert hyphens to valid Go identifier)
- The `agent:` key is always literal `agent` (the map key in the index provides the friendly name)
- Tags should include the tool name and relevant keywords

## Step 5: Create cue.mod/module.cue

Create the module definition:

```cue
module: "github.com/start-cli/library/agents/<tool>/<variant>@v1"
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

Agents only depend on the schemas module (no role dependency).

## Step 6: Publish

Before publishing, confirm the agent definition is complete: `command` is set with the placeholders the tool needs, `bin` is set for auto-detection, and any `default_model` names a key in `models`.

Then load the publishing workflow and follow it end to end:

```bash
start get contexts:start/library/publishing
```

It is the single source for validation, version determination, the mandatory index update, the single module-plus-index commit, the tag pushes, the registry publish, verification, and closing any related GitHub issue. This is a create, so the module starts at v1.0.0.
