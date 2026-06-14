package update

import "github.com/start-cli/library/schemas@v1"

task: schemas.#Task & {
	description: "Update an existing context definition in the library repository"
	tags: ["library", "context", "update", "cue", "interactive"]
	uses: ["contexts:start/library/publishing"]
	file: "@module/task.md"
	prompt: """
		Read {{.file}} to understand your task.
		{{if .instructions}}

		Context path: {{.instructions}}
		{{else}}

		No context path was supplied. Ask the user which context they want to update.
		{{end}}
		"""
}
