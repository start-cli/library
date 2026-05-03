package schemas

// #Settings defines the schema for global start configuration settings.
// Settings control default behavior and runtime options.
//
// All fields are optional. When not specified, sensible defaults are used.
#Settings: {
	// default_agent is the agent to use when --agent flag is not specified.
	// Must match a key in the agents configuration.
	default_agent?: string & !=""

	// shell is the default shell for command execution.
	// If not specified, auto-detects (bash > sh).
	shell?: string & !=""

	// timeout is the default command timeout in seconds.
	// Applies to UTD command execution when not overridden per-context.
	timeout?: int & >0

	// library_index is the CUE module path for the start library index.
	// When set, overrides the default index used by all module commands and doctor.
	library_index?: string & !=""
}
