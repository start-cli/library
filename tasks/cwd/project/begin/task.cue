package begin

import "github.com/start-cli/library/schemas@v1"

task: schemas.#Task & {
	description: "Begin working on the current project with full context"
	tags: ["cwd", "project", "begin", "implementation", "active", "current"]
	file: "@module/task.md"
	prompt: """
		Read {{.file}} to understand your task.
		{{if .instructions}}

		## Custom Instructions

		{{.instructions}}
		{{end}}
		"""
}
