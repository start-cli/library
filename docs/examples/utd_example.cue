package schemas

// Examples demonstrating the Unified Template Design (UTD) pattern
// These examples show all valid combinations of file, command, and prompt fields

// Example 1: File only
// Result: File contents become the output
example_file_only: #UTD & {
	file: "./ROLE.md"
}

// Example 2: Command only
// Result: Command output becomes the output
example_command_only: #UTD & {
	command: "git status --short"
}

// Example 3: Prompt only
// Result: Prompt text (with {{.datetime}} resolved)
example_prompt_only: #UTD & {
	prompt: "Current date: {{.datetime}}"
}

// Example 4: File + Command (no prompt)
// File contains placeholders, command provides data
example_file_command: #UTD & {
	file:    "./PROJECT.md"
	command: "git log -5 --oneline"
	// If PROJECT.md contains {{.command_output}}, it will be replaced
}

// Example 5: File + Prompt
// Prompt can reference file path or contents
example_file_prompt: #UTD & {
	file:   "~/reference/ENVIRONMENT.md"
	prompt: "Read {{.file}} for environment context."
}

// Example 6: Command + Prompt
// Prompt references command or its output
example_command_prompt: #UTD & {
	command: "git status --short"
	prompt: """
		Current status:
		{{.command_output}}

		Review the changes above.
		"""
}

// Example 7: File + Command + Prompt
// All three work together
example_all_three: #UTD & {
	file:    "./PROJECT.md"
	command: "git status --short"
	prompt: """
		Project Documentation:
		{{.file_contents}}

		Current Status:
		{{.command_output}}
		"""
}

// Example 8: Shell override
// Use a different interpreter for the command
example_node_shell: #UTD & {
	shell:   "node"
	command: "console.log(process.version)"
	prompt:  "Node version: {{.command_output}}"
}

// Example 9: Command timeout override
// Commands that might take longer
example_timeout: #UTD & {
	command: "npm run build"
	timeout: 180 // 3 minutes
	prompt: """
		Build output:
		{{.command_output}}
		"""
}

// Example 10: Go template conditionals
example_conditional: #UTD & {
	command: "git status --short"
	prompt: """
		{{if .command_output}}
		Changes detected:
		{{.command_output}}
		{{else}}
		Working tree is clean.
		{{end}}
		"""
}

// Example 11: Multiple placeholders
example_multiple_placeholders: #UTD & {
	file:    "./README.md"
	command: "git log -1 --oneline"
	prompt: """
		Documentation: {{.file}}
		Contents: {{.file_contents}}

		Latest commit: {{.command}}
		Output: {{.command_output}}

		Generated at: {{.datetime}}
		"""
}

// INVALID: This will fail at runtime (Go validation)
// No file, command, or prompt provided
// example_invalid: #UTD & {
//     shell: "bash"
// }
