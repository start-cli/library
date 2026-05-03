package index

import "github.com/start-cli/library/schemas@v1"

// Agent index - maps friendly names to module paths with bin for detection
agents: [string]: schemas.#IndexEntry

agents: {
	"claude/interactive": {
		module:      "github.com/start-cli/library/agents/claude/interactive@v0"
		version:     "v0.1.0"
		description: "Claude Code by Anthropic - agentic coding assistant"
		bin:         "claude"
		tags: ["anthropic", "claude", "coding", "agent"]
	}
}

// Role index - maps friendly names to module paths
roles: [string]: schemas.#IndexEntry

roles: {
	"golang/assistant": {
		module:      "github.com/start-cli/library/roles/golang/assistant@v0"
		version:     "v0.1.0"
		description: "Go programming language expert - collaborative assistant mode"
		tags: ["golang", "programming", "assistant", "collaborative"]
	}
}

// Context index - maps friendly names to module paths
contexts: [string]: schemas.#IndexEntry

contexts: {
	"cwd/agents-md": {
		module:      "github.com/start-cli/library/contexts/cwd/agents-md@v0"
		version:     "v0.1.0"
		description: "Repository-specific AI agent guidelines from AGENTS.md"
		tags: ["agents", "repository", "guidelines", "cwd"]
	}
	"cwd/dotai/workspace": {
		module:      "github.com/start-cli/library/contexts/cwd/dotai/workspace@v0"
		version:     "v0.1.0"
		description: "Workspace context from .ai/workspace.md"
		tags: ["dotai", "cwd", "workspace"]
	}
}

// Task index - maps friendly names to module paths
tasks: [string]: schemas.#IndexEntry

tasks: {
	"review/git-diff": {
		module:      "github.com/start-cli/library/tasks/review/git-diff@v0"
		version:     "v0.1.0"
		description: "Comprehensive review of code changes from git diff to catch regressions and bugs"
		tags: ["review", "diff", "regression", "code-changes", "code-quality"]
	}
}
