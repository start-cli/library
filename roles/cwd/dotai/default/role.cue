package default

import "github.com/start-cli/library/schemas@v1"

role: schemas.#Role & {
	description: "Project-specific default role from .ai/roles/default.md"
	tags: ["dotai", "cwd", "project", "default"]
	file:     ".ai/roles/default.md"
	optional: true
}
