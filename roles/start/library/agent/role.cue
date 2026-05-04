package agent

import "github.com/start-cli/library/schemas@v1"

role: schemas.#Role & {
	description: "library expert - autonomous agent mode"
	tags: ["library", "cue", "agent", "autonomous"]
	file: "@module/role.md"
}
