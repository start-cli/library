package teacher

import "github.com/start-cli/library/schemas@v1"

role: schemas.#Role & {
	description: "EndeavourOS Linux system administration expert - instructional teacher mode"
	tags: ["linux", "endeavouros", "arch", "system-administration", "teacher", "instructional", "learning"]
	file: "@module/role.md"
}
