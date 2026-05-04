package assistant

import "github.com/start-cli/library/schemas@v1"

role: schemas.#Role & {
	description: "start-cli/library expert - collaborative assistant mode"
	tags: ["start-cli/library", "cue", "assistant", "collaborative"]
	file: "@module/role.md"
}
