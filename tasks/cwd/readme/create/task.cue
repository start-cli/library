package create

import (
	"github.com/start-cli/library/schemas@v1"
	agentRole "github.com/start-cli/library/roles/markdown/low-token/agent@v1:agent"
)

task: schemas.#Task & {
	description: "Create a README.md for the current working directory"
	tags: ["readme", "cwd", "documentation", "markdown"]
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
