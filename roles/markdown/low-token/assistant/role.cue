package assistant

import "github.com/start-cli/library/schemas@v1"

role: schemas.#Role & {
	description: "Low-token markdown expert - collaborative assistant mode"
	tags: ["markdown", "low-token", "commonmark", "assistant", "collaborative"]
	file: "@module/role.md"
}
