# Update Agent

Update an existing agent definition in the library repository. This is primarily a design and discussion process — understanding what the agent definition is doing wrong or not doing, and agreeing on the changes before implementing them.

## Prerequisites

- The agent path (e.g., `claude/interactive`, `gemini/non-interactive`)
- Write access to the library repository
- CUE CLI installed (`cue version`)

## Process

Steps:

1. Identify the agent to update
2. Read the current agent file
3. Understand the problem
4. Design the changes
5. Implement the changes
6. Validate
7. Publish
8. Close related GitHub issue (if applicable)

## Step 1: Identify the Agent

If an agent path was supplied in the instructions, use it.

Otherwise, ask the user which agent they want to update and confirm the full path under agents/.

## Step 2: Read the Current Agent File

Read the existing file for the agent:

- `agents/<tool>/<variant>/agent.cue` — the full agent definition

Note: Agent definitions have no markdown file. The entire definition is in `agent.cue`.

Summarise the current agent configuration to the user so they can confirm your understanding before proceeding.

## Step 3: Understand the Problem

Ask the user to describe what the agent is doing wrong or what it is not doing.

Probe with questions if needed:

- Is the command template incorrect or missing flags?
- Are the model identifiers outdated?
- Is the role injection approach wrong for the target tool?
- Is the binary name incorrect for auto-detection?
- Is the description or tags inaccurate?

Do not proceed until the problem is clearly understood.

## Step 4: Design the Changes

This is the core of the update process. Discuss the proposed changes with the user before writing anything.

- Describe what you plan to change and why
- For command template changes, confirm the exact flag syntax with the user
- For model changes, confirm the full model identifiers
- Confirm the approach with the user before proceeding

Do not implement until the design is agreed.

## Step 5: Implement the Changes

Apply the agreed changes to `agent.cue`.

Update only the fields that are changing.

## Step 6: Validate

Run validation from the agent directory:

```bash
cd agents/<tool>/<variant>
cue mod tidy
cue vet agent.cue
cue export agent.cue
```

Expected results:

- `cue mod tidy` completes without errors
- `cue vet agent.cue` produces no output (valid)
- `cue export agent.cue` shows valid JSON with agent definition

## Step 7: Publish

Determine the next patch version for the agent and the index:

```bash
git ls-remote --tags origin | grep "refs/tags/agents/<tool>/<variant>/" | sort -t/ -k<n> -V | tail -1
git ls-remote --tags origin | grep "refs/tags/index/" | sort -t/ -k4 -V | tail -1
```

Update the version in `index/index.cue` for the agent entry, then stage both in a single commit:

```bash
git add agents/<tool>/<variant>/
git add index/index.cue
git commit -m "fix(agents): update <tool>/<variant> agent"
git tag "agents/<tool>/<variant>/${VERSION}"
git tag "index/${INDEX_VERSION}"
git push origin main
git push origin "agents/<tool>/<variant>/${VERSION}"
git push origin "index/${INDEX_VERSION}"

cd agents/<tool>/<variant>
cue mod publish ${VERSION}

cd <repo-root>/index
cue mod publish ${INDEX_VERSION}
```

Important: The CUE registry has tag immutability. Always check the latest remote tag with `git ls-remote` before tagging to avoid version conflicts.

## Step 8: Close Related GitHub Issue

If a GitHub issue exists for this update, close it:

```bash
gh issue close <issue-number> --repo start-cli/library --comment "Fixed in agents/<tool>/<variant>@${VERSION}"
```
