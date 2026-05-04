package update

import "github.com/start-cli/library/schemas@v1"

task: schemas.#Task & {
	description: "Update an existing agent definition in the library repository"
	tags: ["library", "agent", "update", "cue", "interactive"]
	file: "@module/task.md"
	prompt: """
		Read {{.file}} to understand your task.
		{{if .instructions}}

		Agent path: {{.instructions}}
		{{else}}

		No agent path was supplied. Ask the user which agent they want to update.
		{{end}}
		"""
}
