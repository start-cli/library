package testing

import "github.com/start-cli/library/schemas@v1"

task: schemas.#Task & {
	description: "Evaluate test quality, coverage, and the testability of production code"
	tags: ["review", "testing", "tests", "coverage", "code-quality"]
	file: "@module/task.md"
	prompt: """
		Read {{.file}} to understand your task.
		{{if .instructions}}

		## Custom Instructions

		{{.instructions}}
		{{end}}
		"""
}
