package teacher

import "github.com/start-cli/library/schemas@v1"

role: schemas.#Role & {
	description: "Low-token markdown expert - patient teacher mode"
	tags: ["markdown", "low-token", "commonmark", "teacher", "educational"]
	file: "@module/role.md"
}
