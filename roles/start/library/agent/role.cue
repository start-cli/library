package agent

import "github.com/start-cli/library/schemas@v1"

role: schemas.#Role & {
	description: "start-cli/library expert - autonomous agent mode"
	tags: ["start-cli/library", "cue", "agent", "autonomous"]
	file: "@module/role.md"
}
