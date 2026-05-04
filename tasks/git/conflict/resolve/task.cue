package resolve

import (
	"github.com/start-cli/library/schemas@v1"
	assistantRole "github.com/start-cli/library/roles/git/assistant@v1:assistant"
)

task: schemas.#Task & {
	description: "Resolve git conflicts from merge, rebase, cherry-pick, revert, stash, and patch operations"
	tags: ["git", "merge", "rebase", "conflict", "resolve"]
	role: assistantRole.role
	file: "@module/task.md"
	prompt: """
		{{.file_contents}}
		{{if .instructions}}

		## Custom Instructions

		{{.instructions}}
		{{end}}
		"""
}
