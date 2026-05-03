package schemas

// Examples demonstrating context definitions
// Contexts provide environment, project, and domain-specific information to AI agents

// User applies global defaults via pattern constraint
contexts: [_]: #Context & {
	timeout: *30 | _          // Global default: 30 seconds
	shell:   *"/bin/bash" | _ // Global default shell
}

// Example 1: Required context (always included)
// Essential environment information for every session
contexts: "environment": {
	required:    true
	description: "Local environment and user preferences"
	file:        "~/reference/ENVIRONMENT.md"
	prompt:      "Environment context:\n{{.file_contents}}"
}

// Example 2: Required context with command
// Repository information always needed
contexts: "agents": {
	required:    true
	description: "Repository-specific AI agent guidelines"
	file:        "./AGENTS.md"
	command:     "git remote get-url origin 2>/dev/null || echo 'No git remote'"
	prompt: """
		Repository: {{.command_output}}

		Agent guidelines:
		{{.file_contents}}
		"""
}

// Example 3: Default context (included in plain `start`)
// Project context for interactive sessions
contexts: "project": {
	default:     true
	description: "Current project documentation"
	file:        "./PROJECT.md"
	prompt:      "Project context:\n{{.file_contents}}"
}

// Example 4: Tagged context (golang)
// Only included with `--context golang`
contexts: "golang-conventions": {
	description: "Go language conventions and best practices"
	tags: ["golang", "programming"]
	file: "~/.config/start/contexts/golang.md"
	prompt: """
		Go Conventions:
		{{.file_contents}}

		Apply these conventions to all Go code.
		"""
}

// Example 5: Tagged context (security)
// Only included with `--context security`
contexts: "security-checklist": {
	description: "Security review checklist"
	tags: ["security", "review"]
	prompt: """
		Security Checklist:
		- Check for injection vulnerabilities (SQL, command, XSS)
		- Verify input validation and sanitization
		- Review authentication and authorization
		- Check for sensitive data exposure
		- Verify cryptographic implementations
		"""
}

// Example 6: Tagged context with dynamic content
// Loads current git state for code review contexts
contexts: "git-state": {
	description: "Current git repository state"
	tags: ["git", "review", "code-review"]
	command: "git status --short && echo '---' && git log -3 --oneline"
	prompt: """
		Current Git State:
		{{.command_output}}
		"""
	timeout: 10
}

// Example 7: Multi-tag context
// Included with any of: frontend, react, typescript
contexts: "frontend-react": {
	description: "React and TypeScript conventions"
	tags: ["frontend", "react", "typescript"]
	file: "~/.config/start/contexts/react.md"
	prompt: """
		React/TypeScript Conventions:
		{{.file_contents}}
		"""
}

// Example 8: Default AND tagged context
// Included in plain `start` OR when tag matches
contexts: "documentation-index": {
	default:     true
	description: "Reference documentation index"
	tags: ["docs", "reference"]
	file: "~/reference/INDEX.csv"
	prompt: """
		Documentation Index:
		{{.file_contents}}

		Use this index to find relevant reference materials.
		"""
}

// Example 9: Required with tags (redundant but valid)
// Tags are ignored since required is always included
contexts: "core-config": {
	required:    true
	description: "Core configuration context"
	tags: ["config"] // Redundant - always included anyway
	file: "~/.config/start/settings.cue"
	prompt: "Configuration:\n{{.file_contents}}"
}

// Example 10: Node.js specific context
contexts: "nodejs-conventions": {
	description: "Node.js and npm conventions"
	tags: ["nodejs", "javascript", "npm"]
	shell:   "node"
	command: "console.log(`Node ${process.version}`)"
	file:    "~/.config/start/contexts/nodejs.md"
	prompt: """
		Node.js Environment: {{.command_output}}

		Conventions:
		{{.file_contents}}
		"""
}
