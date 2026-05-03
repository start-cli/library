package schemas

// #Context defines the schema for context documents.
// Contexts provide environment, project, and domain-specific information to AI agents.
//
// Note: Contexts are identified by their map key (e.g., contexts["environment"]).
// There is no 'name' field - the key IS the name.
//
// Selection behavior:
// - required: true = always included, every command
// - default: true = included in plain `start`, not with --context
// - tags = included when matching tag requested via --context
//
// See: DR-008 for full selection and tagging behavior
#Context: {
	// Embed common fields (description, tags, origin)
	#Base

	// Embed UTD pattern (file, command, prompt, shell, timeout)
	#UTD

	// Selection behavior
	required?: bool // Always included in all commands
	default?:  bool // Included in plain `start` only
}
