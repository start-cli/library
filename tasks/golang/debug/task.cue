package debug

import (
	"github.com/start-cli/library/schemas@v1"
	agentRole "github.com/start-cli/library/roles/golang/agent@v1:agent"
)

task: schemas.#Task & {
	description: "Systematically debug and resolve issues in Go code"
	tags: ["golang", "debug", "troubleshooting", "bugs", "investigation"]
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
