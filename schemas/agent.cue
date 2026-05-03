package schemas

// #Agent defines the schema for AI agent configurations.
// Agents are command templates that launch AI CLI tools.
//
// Note: Agents are identified by their map key (e.g., agents["claude"]).
// There is no 'name' field - the key IS the name.
//
// Unlike other schemas, agents do NOT use UTD.
// They define command templates with placeholders for runtime substitution.
#Agent: {
	// Embed common fields (description, tags, origin)
	#Base

	// Command template (required, must not be empty)
	// Placeholders: {{.bin}}, {{.model}}, {{.prompt}}, {{.role}}, {{.role_file}}
	command: string & !=""

	// Binary name for auto-detection and {{.bin}} placeholder
	bin?: string & !=""

	// Model configuration
	default_model?: string
	models?: [string]: string & !=""
}
