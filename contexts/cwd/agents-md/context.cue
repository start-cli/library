package agentsmd

import "github.com/start-cli/library/schemas@v1"

context: schemas.#Context & {
	required:    true
	default:     true
	description: "Repository-specific AI agent guidelines from AGENTS.md"
	tags: ["agents", "repository", "guidelines", "cwd"]
	file:    "AGENTS.md"
	command: "git remote get-url origin 2>/dev/null || echo 'No git remote'"
	prompt: """
		Read the {{.file}} file for repository context.
		Repository: {{.command_output}}
		"""
}
