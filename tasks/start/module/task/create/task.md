# Create Task

Create a new task in the library repository. This is an interactive process.

## Prerequisites

Confirm these values with the user before starting:

- Task Name: kebab-case identifier (e.g., `code-review`, `github-homebrew-release`)
- Category Path: Directory path under tasks/ (e.g., `golang`, `start`, `terraform`)
- Description: Brief description of what the task does
- Role Reference: Which role to use (e.g., `golang/assistant`, `cue/assistant`, or none)
- Source Content: Either:
  - An existing document to adapt
  - A description of what the task should do (to create from scratch)

Requirements:

- Write access to the library repository
- CUE CLI installed (`cue version`)
- Understanding of the task's purpose and workflow

## Task Creation Process

Steps:

1. Gather prerequisites from user
2. Design the task interactively
3. Create directory structure
4. Create task.cue with schema definition
5. Create task.md with instructions
6. Create cue.mod/module.cue with dependencies
7. Publish following the publishing workflow

## Step 1: Gather Prerequisites

Ask the user for:

1. Task name - Must be kebab-case (e.g., `create-task`, `code-review`)
2. Category - Where it lives under tasks/ (e.g., `golang`, `start`, `terraform`)
3. Description - One-line summary for the task
4. Role - Which role to reference, format: `category/type` (e.g., `golang/assistant`)
5. Source - Either a file path to adapt or instructions for what the task should do

Example values:
```
Task name: github-homebrew-release
Category: golang
Description: Release Go project to GitHub with Homebrew tap distribution
Role: golang/assistant
Source: /path/to/existing-document.md (or describe the workflow)
```

## Step 2: Design the Task

Before creating any files, discuss and agree on the following with the user:

- Task name — confirm it is self-describing and follows kebab-case
- Category path — confirm where it lives under tasks/, including whether a new sub-category makes sense
- Task behaviour — what the task does step by step, including defaults, optional inputs, and confirmation prompts
- Prompt style — what the agent should say and do at each decision point
- Comment/output format — if the task produces content (e.g., comments, reports), agree on structure and tone

Do not proceed to file creation until the design is agreed.

## Step 3: Create Directory Structure

Create the task directory with cue.mod:

```bash
# Create directory structure (path may be deeper than two levels)
mkdir -p tasks/<category/subcategory/task-name>/cue.mod
```

The path under tasks/ can be as deep as needed. Examples:

```
tasks/golang/debug/           (2 levels)
tasks/jira/item/review/       (3 levels)
tasks/jira/item/comment/git-commit/  (4 levels)
```

Expected structure:
```
tasks/
└── <path>/
    └── <task-name>/
        ├── cue.mod/
        │   └── module.cue
        ├── task.cue
        └── task.md
```

## Step 4: Create task.cue

Create the task schema definition file.

If using a role:

```cue
package <packagename>

import (
	"github.com/start-cli/library/schemas@v1"
	assistantRole "github.com/start-cli/library/roles/<category>/<type>@v1:<type>"
)

task: schemas.#Task & {
	description: "<task description>"
	tags: ["<tag1>", "<tag2>", "<tag3>"]
	role: assistantRole.role
	file: "@module/task.md"
	prompt: """
		{{.file_contents}}
		{{if .instructions}}

		## Custom Instructions

		{{.instructions}}
		{{end}}
		"""
}
```

If no role:

```cue
package <packagename>

import "github.com/start-cli/library/schemas@v1"

task: schemas.#Task & {
	description: "<task description>"
	tags: ["<tag1>", "<tag2>", "<tag3>"]
	file: "@module/task.md"
	prompt: """
		{{.file_contents}}
		{{if .instructions}}

		## Custom Instructions

		{{.instructions}}
		{{end}}
		"""
}
```

Notes:
- Package name: Convert task name to valid Go identifier (remove hyphens, use camelCase or single word)
- Tags: Use kebab-case, include relevant categories and keywords
- The `@module/` prefix resolves to the task's directory at runtime

Prompt pattern — choose based on the size of task.md:

- `{{.file_contents}}` — embeds the file contents inline in the prompt. Use for small task files where the full content fits naturally in the prompt.
- `Read {{.file}} to understand your task.` — instructs the agent to read the file itself. Use for long task files to avoid embedding large content directly.

## Step 5: Create task.md

Create the task instructions file. This is the main content that guides the AI agent.

Structure guidelines:

```markdown
# Task Title

Brief description of what this task accomplishes.

## Prerequisites

What the user needs to provide or have available before starting.

## Process

Steps:

1. Step one
2. Step two
3. ...

## Step 1: First Step

Detailed instructions for step 1.

```bash
# Commands if applicable
```

## Step 2: Second Step

Detailed instructions for step 2.

...

## Troubleshooting

Common issues and solutions (if applicable).
```

Content guidelines:

- Write for an AI agent to execute
- Be explicit about what commands to run
- Include expected results for validation
- Use markdown code blocks for commands
- Include decision points where user input is needed
- Keep steps atomic and verifiable

## Step 6: Create cue.mod/module.cue

Create the module definition with dependencies.

If using a role:

```cue
module: "github.com/start-cli/library/tasks/<category>/<task-name>@v1"
language: {
	version: "v0.16.0"
}
source: {
	kind: "git"
}
deps: {
	"github.com/start-cli/library/roles/<role-category>/<role-type>@v1": {
		v: "v1.0.0"
	}
	"github.com/start-cli/library/schemas@v1": {
		v: "v1.0.0"
	}
}
```

If no role:

```cue
module: "github.com/start-cli/library/tasks/<category>/<task-name>@v1"
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

## Step 7: Publish

Before publishing, confirm the task is complete: `task.md` and `task.cue` are written, the prompt pattern fits the size of `task.md` (`{{.file_contents}}` for small files, `Read {{.file}}` for long ones), and any referenced role resolves.

Then load the publishing workflow and follow it end to end:

```bash
start get contexts:start/library/publishing
```

It is the single source for validation, version determination, the mandatory index update, the single module-plus-index commit, the tag pushes, the registry publish, verification, and closing any related GitHub issue. This is a create, so the module starts at v1.0.0.
