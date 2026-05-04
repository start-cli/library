package index

import "github.com/start-cli/library/schemas@v1"

context: schemas.#Context & {
	description: "Index of curated reference material in .ai/context/"
	tags: ["dotai", "cwd", "context", "index", "reference"]
	command: "cat .ai/context/*/index.csv 2>/dev/null | sort -u || echo 'No context index found'"
	prompt:  "Project reference material index from .ai/context/:\n{{.command_output}}"
}
