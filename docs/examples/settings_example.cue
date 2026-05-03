package schemas

// Examples demonstrating settings configuration
// Settings control default behavior and runtime options

// Example 1: Minimal settings with just default agent
// Most common configuration after auto-setup
settings: #Settings & {
	default_agent: "claude"
}

// Example 2: Full settings configuration
// All available settings specified
_fullSettings: #Settings & {
	default_agent: "gemini"
	shell:         "/bin/zsh"
	timeout:       120
}

// Example 3: Local project override
// In .start/settings.cue to override global settings
_localSettings: #Settings & {
	default_agent: "ollama" // Use local LLM for this project
	timeout:       60       // Faster timeout for local commands
}

// Example 4: Settings with custom shell
// For environments with non-standard shell requirements
_customShellSettings: #Settings & {
	default_agent: "claude"
	shell:         "/usr/local/bin/fish"
}
