package project

import "github.com/start-cli/library/schemas@v1"

context: schemas.#Context & {
	default:     true
	description: "Project-specific documentation from project.md"
	tags: ["project", "repository", "documentation", "cwd"]
	file:   "project.md"
	prompt: "Read the {{.file}} file to gain context about the current project."
}
