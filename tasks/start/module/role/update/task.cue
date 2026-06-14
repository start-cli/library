package update

import "github.com/start-cli/library/schemas@v1"

task: schemas.#Task & {
	description: "Update an existing role in the library repository"
	tags: ["library", "role", "update", "cue", "interactive"]
	uses: ["contexts:start/library/publishing", "tasks:start/module/role/create"]
	file: "@module/task.md"
	prompt: """
		Read {{.file}} to understand your task.
		{{if .instructions}}

		Role path: {{.instructions}}
		{{else}}

		No role path was supplied. Ask the user which role they want to update.
		{{end}}
		"""
}
