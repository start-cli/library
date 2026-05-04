package css

import "github.com/start-cli/library/schemas@v1"

task: schemas.#Task & {
	description: "Review CSS stylesheets for consistency, maintainability, and correctness"
	tags: ["review", "css", "stylesheets", "front-end", "code-quality"]
	file: "@module/task.md"
	prompt: """
		Read {{.file}} to understand your task.
		{{if .instructions}}

		## Custom Instructions

		{{.instructions}}
		{{end}}
		"""
}
