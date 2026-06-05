package schemas

// #Role defines the schema for AI agent roles (system prompts).
// Roles define what the AI agent is and how it should behave.
//
// Note: Roles are identified by their map key (e.g., roles["code-reviewer"]).
// There is no 'name' field - the key IS the name.
//
// Roles use the UTD pattern to build the system prompt from
// static files, dynamic command output, and template text.
#Role: {
	// Embed common fields (description, tags, origin)
	#Base

	// Embed UTD pattern (file, command, prompt, shell, timeout)
	#UTD

	// Whether this role can be skipped if its file is missing.
	// Optional roles are discovery-based (e.g., dotagents roles that look for
	// .agents/roles/default.md). When file is missing:
	// - optional: true → skip, try next role in definition order
	// - optional: false → error, stop execution
	// Explicit --role flag always errors on failure.
	optional: bool | *false
}
