# Contexts

Context definitions providing environmental information for AI agents.

Each subdirectory contains a CUE package defining a context with structured data about the working environment. Contexts inject relevant information into prompts based on selection behaviour.

## Structure

```
contexts/<scope>/<name>/
├── context.cue
└── cue.mod/module.cue
```

## Selection Behaviour

- `required: true` - Always included in every command
- `default: true` - Included in plain `start`, excluded with explicit `--context`
- `tags` - Included when the matching tag is requested via `--context`

## Available Contexts

### cwd/ (current working directory)

- [cwd/agents-md](cwd/agents-md/) - Repository-specific agent guidelines from `AGENTS.md`
- [cwd/project](cwd/project/) - Project-specific documentation from `project.md`
- [cwd/dotai/workspace](cwd/dotai/workspace/) - Workspace settings from `./.ai/`
- [cwd/dotai/context/index](cwd/dotai/context/index/) - Index of curated reference material in `./.ai/context/`

### home/ (user-home configuration)

- [home/dotai/environment](home/dotai/environment/) - Local environment information (user, system, tools)
- [home/dotai/workflow](home/dotai/workflow/) - Feature-development workflow
- [home/dotai/context/index](home/dotai/context/index/) - Index of curated reference material in `~/.ai/context/`
