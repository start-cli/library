package schemas

// #UTD defines the Unified Template Design pattern.
// Used by roles, contexts, and tasks to build prompt text from
// static files, dynamic command output, and template text.
//
// At least one of file, command, or prompt must be present.
// This constraint is validated by Go at runtime (CUE cannot
// express "at least one" constraints cleanly).
//
// Resolution priority: prompt > file > command
// - If prompt exists, it wins (other fields provide input data)
// - If only file and command, file wins (command can be injected)
// - If only one field, that field determines the output
//
// See: UTD pattern documentation in the start CLI repo for complete documentation
#UTD: {
	// Content source fields (at least one required)
	file?:    string // Path to file (provides {{.file}}, {{.file_contents}})
	command?: string // Shell command (provides {{.command}}, {{.command_output}})
	prompt?:  string // Go template syntax with placeholders

	// Shell configuration (optional overrides)
	shell?:   string & !=""      // Override global shell (bash, sh, node, python, etc.)
	timeout?: int & >=1 & <=3600 // Timeout in seconds (no default - set in user config)
}
