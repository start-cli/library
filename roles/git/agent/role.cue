package agent

import "github.com/start-cli/library/schemas@v1"

role: schemas.#Role & {
	description: "Git version control expert - autonomous agent mode"
	tags: ["git", "version-control", "vcs", "agent", "autonomous"]
	file: "@module/role.md"
}
