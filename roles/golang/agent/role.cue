package agent

import "github.com/start-cli/library/schemas@v1"

role: schemas.#Role & {
	description: "Go programming language expert - autonomous agent mode"
	tags: ["golang", "programming", "agent", "autonomous", "automation"]
	file: "@module/role.md"
}
