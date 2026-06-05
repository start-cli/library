package default

import "github.com/start-cli/library/schemas@v1"

role: schemas.#Role & {
	description: "Project-specific default role from .agents/roles/default.md"
	tags: ["dotagents", "cwd", "project", "default"]
	file:     ".agents/roles/default.md"
	optional: true
}
