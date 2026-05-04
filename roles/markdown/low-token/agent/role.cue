package agent

import "github.com/start-cli/library/schemas@v1"

role: schemas.#Role & {
	description: "Low-token markdown expert - autonomous agent mode"
	tags: ["markdown", "low-token", "commonmark", "agent", "autonomous"]
	file: "@module/role.md"
}
