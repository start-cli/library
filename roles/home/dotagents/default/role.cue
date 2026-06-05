package default

import "github.com/start-cli/library/schemas@v1"

role: schemas.#Role & {
	description: "User's global default role from ~/.agents/roles/default.md"
	tags: ["dotagents", "home", "global", "default"]
	file:     "~/.agents/roles/default.md"
	optional: true
}
