package update

import "github.com/start-cli/library/schemas@v1"

task: schemas.#Task & {
	description: "Update an existing task in the library repository"
	tags: ["library", "task", "update", "cue", "interactive"]
	uses: ["contexts:start/library/publishing"]
	file: "@module/task.md"
	prompt: """
		Read {{.file}} to understand your task.
		{{if .instructions}}

		Task path: {{.instructions}}
		{{else}}

		No task path was supplied. Ask the user which task they want to update.
		{{end}}
		"""
}
