package assistant

import "github.com/start-cli/library/schemas@v1"

role: schemas.#Role & {
	description: "library expert - collaborative assistant mode"
	tags: ["library", "cue", "assistant", "collaborative"]
	file: "@module/role.md"
}
