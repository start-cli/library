package triage

import "github.com/start-cli/library/schemas@v1"

task: schemas.#Task & {
	description: "Investigate the next GitHub issue, analyse code, and assess effort"
	tags: ["github", "issue", "triage", "investigation", "planning"]
	file: "@module/task.md"
	prompt: """
		Read {{.file}} to understand your task.
		{{if .instructions}}

		## Custom Instructions

		{{.instructions}}
		{{end}}
		"""
}
