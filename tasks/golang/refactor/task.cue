package refactor

import (
	"github.com/start-cli/library/schemas@v1"
	agentRole "github.com/start-cli/library/roles/golang/agent@v1:agent"
)

task: schemas.#Task & {
	description: "Refactor Go code to improve structure, readability, and maintainability"
	tags: ["golang", "refactor", "code-quality", "maintainability", "structure"]
	role: agentRole.role
	file: "@module/task.md"
	prompt: """
		Read {{.file}} to understand your task.
		{{if .instructions}}

		## Custom Instructions

		{{.instructions}}
		{{end}}
		"""
}
