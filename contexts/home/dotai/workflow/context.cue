package workflow

import "github.com/start-cli/library/schemas@v1"

context: schemas.#Context & {
	description: "Feature development workflow for Documentation Driven Development"
	tags: ["dotai", "home", "workflow", "development"]
	file:   "~/.ai/workflow.md"
	prompt: "Read the {{.file}} file to understand the feature development workflow."
}
