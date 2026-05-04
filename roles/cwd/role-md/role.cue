package role

import "github.com/start-cli/library/schemas@v1"

role: schemas.#Role & {
	description: "Project-specific role from role.md"
	tags: ["cwd", "project", "role"]
	file:     "role.md"
	optional: true
}
