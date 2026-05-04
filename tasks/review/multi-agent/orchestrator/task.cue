package orchestrator

import "github.com/start-cli/library/schemas@v1"

task: schemas.#Task & {
	description: "Spawn parallel review agents for comprehensive code analysis"
	tags: ["review", "orchestration", "multi-agent", "parallel"]
	file: "@module/task.md"
	prompt: """
		Read {{.file}} to understand your task.
		{{if .instructions}}

		## Custom Instructions

		{{.instructions}}
		{{end}}
		"""
}
