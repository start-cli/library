package teacher

import "github.com/start-cli/library/schemas@v1"

role: schemas.#Role & {
	description: "start-cli/library expert - educational teacher mode"
	tags: ["start-cli/library", "cue", "teacher", "educational"]
	file: "@module/role.md"
}
