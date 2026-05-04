package standards

import "github.com/start-cli/library/schemas@v1"

task: schemas.#Task & {
	description: "Verify changes meet applicable domain-specific standards and requirements"
	tags: ["review", "standards", "compliance", "accessibility", "code-quality"]
	file: "@module/task.md"
	prompt: """
		Read {{.file}} to understand your task.
		{{if .instructions}}

		## Custom Instructions

		{{.instructions}}
		{{end}}
		"""
}
