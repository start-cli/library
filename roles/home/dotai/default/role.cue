package default

import "github.com/start-cli/library/schemas@v1"

role: schemas.#Role & {
	description: "User's global default role from ~/.ai/roles/default.md"
	tags: ["dotai", "home", "global", "default"]
	file:     "~/.ai/roles/default.md"
	optional: true
}
