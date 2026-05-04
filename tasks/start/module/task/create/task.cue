package create

import (
	"github.com/start-cli/library/schemas@v1"
	assistantRole "github.com/start-cli/library/roles/start/library/assistant@v1:assistant"
)

task: schemas.#Task & {
	description: "Create a new task in the library repository"
	tags: ["library", "task", "create", "cue", "interactive"]
	role: assistantRole.role
	file: "@module/task.md"
	prompt: """
		Read {{.file}} to understand your task.
		{{if .instructions}}

		## Custom Instructions

		{{.instructions}}
		{{end}}
		"""
}
