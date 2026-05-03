package workspace

import "github.com/start-cli/library/schemas@v1"

context: schemas.#Context & {
	required:    true
	default:     true
	description: "Workspace context from .ai/workspace.md"
	tags: ["dotai", "cwd", "workspace"]
	file:   ".ai/workspace.md"
	prompt: "Read the {{.file}} file for workspace context."
}
