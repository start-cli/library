package teacher

import "github.com/start-cli/library/schemas@v1"

role: schemas.#Role & {
	description: "library expert - educational teacher mode"
	tags: ["library", "cue", "teacher", "educational"]
	file: "@module/role.md"
}
