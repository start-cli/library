package performance

import "github.com/start-cli/library/schemas@v1"

task: schemas.#Task & {
	description: "Analyse code efficiency and resource usage"
	tags: ["review", "performance", "efficiency", "resources", "code-quality"]
	file: "@module/task.md"
	prompt: """
		Read {{.file}} to understand your task.
		{{if .instructions}}

		## Custom Instructions

		{{.instructions}}
		{{end}}
		"""
}
