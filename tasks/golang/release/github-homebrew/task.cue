package github_homebrew

import (
	"github.com/start-cli/library/schemas@v1"
	assistantRole "github.com/start-cli/library/roles/golang/assistant@v1:assistant"
)

task: schemas.#Task & {
	description: "Release Go project to GitHub with Homebrew tap distribution"
	tags: ["golang", "release", "github", "homebrew", "ci-cd"]
	role: assistantRole.role
	file: "@module/task.md"
	prompt: """
		Read {{.file}} to understand your task.
		{{if .instructions}}

		## Custom Instructions

		{{.instructions}}
		{{end}}
		"""
}
