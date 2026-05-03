# Roles

Role definitions providing system prompts and behavioural instructions for AI agents.

Each subdirectory contains CUE packages defining roles with prompts, instructions, and optional restrictions.

## Structure

```
roles/<category>/<style>/
├── role.cue
└── cue.mod/module.cue
```

## Available Roles

- [golang/agent/](golang/agent/) - Go programming agent role
- [golang/assistant/](golang/assistant/) - Go programming assistant role
- [golang/teacher/](golang/teacher/) - Go programming teacher role
