package begin

import "github.com/start-cli/library/schemas@v1"

task: schemas.#Task & {
	description: "Start working on the current project with full context"
	tags: ["cwd", "project", "start", "implementation", "active", "current"]
	file: "@module/task.md"
	prompt: """
		Read {{.file}} to understand your task.
		{{if .instructions}}

		## Custom Instructions

		{{.instructions}}
		{{end}}
		"""
}
